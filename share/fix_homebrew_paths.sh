
# fix_homebrew_paths.sh — Fix absolute Homebrew library paths in a macOS .app bundle.


# exit immediately if error, unset is an error, pipeline fails if any command in it fails
set -euo pipefail

# Directories
APP_BUNDLE="$1"
CONTENTS="$APP_BUNDLE/Contents"
FRAMEWORKS_DIR="$CONTENTS/Frameworks"
MACOS_DIR="$CONTENTS/MacOS"
mkdir -p "$FRAMEWORKS_DIR"

# do not relocate if system lib
is_system_lib() { [[ "$1" == /System/* || "$1" == /usr/lib/* ]]; }

find_machos() {
    find "$CONTENTS" \( -name '*.dylib' -o -name '*.so' -o -type f -perm +111 \) \
        ! -name '*.plist' ! -name '*.json' ! -name '*.qml' ! -name '*.js' \
        ! -name '*.conf' ! -name '*.xml' ! -name '*.png' ! -name '*.jpg' \
        ! -name '*.svg' ! -name '*.qm' ! -name '*.dat' ! -name '*.pak' \
        ! -name '*.icns' ! -name '*.txt' ! -name '*.metallib' \
        ! -path '*/Headers/*' 2>/dev/null | while read -r f; do
        file "$f" | grep -qiE 'Mach-O|universal binary' && echo "$f"
    done
}

copy_dep() {
    local dep="$1"  # absolute path
    if [[ "$dep" == *".framework/"* ]]; then
        # folder path
        local fw_name; fw_name=$(echo "$dep" | sed -E 's|^(.*\.framework)/.*$|\1|')
        # folder name
        local fw_base; fw_base=$(basename "$fw_name")
        # avoid dup copies
        [[ ! -d "$FRAMEWORKS_DIR/$fw_base" ]] && cp -a "$fw_name" "$FRAMEWORKS_DIR/$fw_base"
        local inner; inner=$(echo "$dep" | sed -E "s|^.*\.framework/||")
        echo "@executable_path/../Frameworks/$fw_base/$inner"
    else
        # plain dylib
        # file name
        local lib; lib=$(basename "$dep")
        # avoid dup copies
        if [[ ! -f "$FRAMEWORKS_DIR/$lib" ]]; then
            cp -L "$dep" "$FRAMEWORKS_DIR/$lib"
            # Make writable so install_name_tool can modify it later!!!
            chmod u+w "$FRAMEWORKS_DIR/$lib"
        fi
        echo "@executable_path/../Frameworks/$lib"
    fi
}


# Runs up to 10 passes because copying a library may introduce NEW absolute deps
#   1. Scans all Mach-O files for absolute Homebrew paths
#   2. Copies those deps into Frameworks/
#   3. Rewrites all references in a single install_name_tool call per binary
for pass in $(seq 1 10); do
    echo ""
    echo "=== Pass $pass ==="

    MACHOS=$(mktemp)
    find_machos > "$MACHOS"
    # absolute paths (starts with /)
    # not system libs (/System/*, /usr/lib/*)
    # not already relocated (@*)
    BAD=$(mktemp)
    while IFS= read -r m; do
        [[ -z "$m" ]] && continue
        otool -L "$m" 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r d; do
            [[ "$d" == @* || "$d" != /* ]] && continue
            is_system_lib "$d" && continue
            echo "$d"
        done
    done < "$MACHOS" | sort -u > "$BAD"  # deduplicate

    count=$(wc -l < "$BAD" | tr -d ' ')
    if [[ $count -eq 0 ]]; then
        echo "  Clean — no absolute non-system deps remain."
        rm -f "$MACHOS" "$BAD"
        break  # all done, exit the loop
    fi
    echo "  $count problematic dep(s)."

    # Copy each bad dep into Frameworks/
    MAP=$(mktemp)
    while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        new=$(copy_dep "$dep")
        # append to mapping file
        printf '%s\t%s\n' "$dep" "$new" >> "$MAP"

        if [[ "$dep" == *".framework/"* ]]; then
            fw_base=$(basename "$(echo "$dep" | sed -E 's|^(.*\.framework)/.*$|\1|')")
            inner=$(echo "$dep" | sed -E "s|^.*\.framework/||")
            target="$FRAMEWORKS_DIR/$fw_base/$inner"
        else
            # plain dylib
            target="$FRAMEWORKS_DIR/$(basename "$dep")"
        fi
        # Set the ID (make writable first, ignore errors for non-Mach-O files!)
        [[ -f "$target" ]] && { chmod u+w "$target" 2>/dev/null || true; install_name_tool -id "$new" "$target" 2>/dev/null || true; }
    done < "$BAD"

    # rescan the bundle and overwrite the temp file
    find_machos > "$MACHOS"

    # batch-rewrite all references in each binary (much faster than one call per dep)
    # - change all bad dep references to new @executable_path paths (-change)
    # - fix the right ID
    while IFS= read -r m; do
        [[ -z "$m" ]] && continue
        # avoids running otool per dep
        otool_out=$(otool -L "$m" 2>/dev/null)

        change_args=()
        while IFS=$'\t' read -r old new; do
            [[ -z "$old" ]] && continue
            echo "$otool_out" | grep -qF "$old" && change_args+=( -change "$old" "$new" ) # only if old
        done < "$MAP"

        # Check if this binary's own install-name ID is an absolute Homebrew path.
        cur_id=$(otool -D "$m" 2>/dev/null | tail -n +2 | head -1)
        if [[ -n "$cur_id" && "$cur_id" == /* && "$cur_id" != /System/* && "$cur_id" != /usr/lib/* ]]; then
            change_args+=( -id "@executable_path/../Frameworks/$(basename "$cur_id")" )
        fi

        # install_name_tool with both -change and -id args
        if [[ ${#change_args[@]} -gt 0 ]]; then
            chmod u+w "$m" 2>/dev/null || true  # ensure
            install_name_tool "${change_args[@]}" "$m" 2>/dev/null || true
            echo "  Fixed $(basename "$m")"
        fi
    done < "$MACHOS"

    rm -f "$MACHOS" "$BAD" "$MAP"

    [[ $pass -eq 10 ]] && { echo "ERROR: still bad deps after 10 passes"; exit 1; }
done


# copy missing @-path deps from Homebrew
# Some binaries reference libs via @loader_path, @rpath, or @executable_path. This finds them and fix broken references!

echo ""
echo "=== missing @-path deps ==="
MACHOS=$(mktemp)
find_machos > "$MACHOS"

while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    # Check each @-relative dependency of this binary
    otool -L "$m" 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r dep; do
        [[ "$dep" != @* ]] && continue
        resolved=""
        case "$dep" in
            # @loader_path = directory containing the binary that loads the lib
            @loader_path/*) resolved="$(dirname "$m")/${dep#@loader_path/}" ;;
            # @executable_path = the MacOS/ directory where the main exe lives
            @executable_path/*) resolved="$MACOS_DIR/${dep#@executable_path/}" ;;
            # @rpath = search path list embedded in the binary (we check Frameworks/ and MacOS/)
            @rpath/*)
                lib="${dep#@rpath/}"
                for c in "$FRAMEWORKS_DIR/$lib" "$MACOS_DIR/$lib"; do
                    [[ -f "$c" ]] && { resolved="$c"; break; }
                done
                # If not found, assume it should be in Frameworks/
                [[ -z "$resolved" ]] && resolved="$FRAMEWORKS_DIR/$lib"
                ;;
        esac
        # If we resolved a path but the file doesn't exist → it's missing
        if [[ -n "$resolved" && ! -f "$resolved" ]]; then
            lib_name=$(basename "$dep")
            [[ -f "$FRAMEWORKS_DIR/$lib_name" ]] && continue # skip if under Frameworks/basename
            # Search common Homebrew directories for the missing lib
            for d in /opt/homebrew/lib /opt/homebrew/opt/*/lib /usr/local/lib /usr/local/opt/*/lib; do
                if [[ -f "$d/$lib_name" ]]; then
                    cp -L "$d/$lib_name" "$FRAMEWORKS_DIR/$lib_name"
                    chmod u+w "$FRAMEWORKS_DIR/$lib_name"
                    install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$FRAMEWORKS_DIR/$lib_name" 2>/dev/null || true
                    echo "  Copied missing: $lib_name"
                    break
                fi
            done
        fi
    done
done < "$MACHOS"
rm -f "$MACHOS"

# if 2 paths exists
# scan LC_RPATH via otool -l
# if needed delete any absolute (but not system) paths
# if needeed, add @exec.../../Frameworks
echo ""
echo "=== strip non-portable rpaths ==="
MACHOS=$(mktemp)
find_machos > "$MACHOS"

while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    # The "|| true" prevents pipefail from killing the script when grep finds nothing
    ( otool -l "$m" 2>/dev/null | grep -A2 LC_RPATH | grep "path " | awk '{print $2}' || true ) | while read -r rp; do
        [[ -z "$rp" || "$rp" == @* ]] && continue # keep @-relative rpaths
        is_system_lib "$rp" && continue # keep system rpaths
        chmod u+w "$m" 2>/dev/null || true
        install_name_tool -delete_rpath "$rp" "$m" 2>/dev/null || true
        echo "  Removed rpath '$rp' from $(basename "$m")"
    done
done < "$MACHOS"

# if needeed, add @exec.../../Frameworks
MAIN_EXE="$MACOS_DIR/salvium-wallet-gui"
if [[ -f "$MAIN_EXE" ]]; then
    if ! ( otool -l "$MAIN_EXE" 2>/dev/null | grep -A2 LC_RPATH | grep -q "@executable_path/../Frameworks" ) 2>/dev/null; then
        install_name_tool -add_rpath "@executable_path/../Frameworks" "$MAIN_EXE" 2>/dev/null || true
        echo "  Added @executable_path/../Frameworks rpath"
    fi
fi
rm -f "$MACHOS"

# install_name_tool invalidates existing signatures, so we must re-sign
echo ""
echo "=== codesigning ==="

find_machos | while read -r f; do
    codesign --force --sign - "$f" 2>/dev/null || true  # --force overwrites invalid sigs
done
# Sign top-level bundle (--deep ensures nested content is covered)
codesign --force --deep --sign - "$APP_BUNDLE"
echo "  Done."

echo ""
echo "=== fix_homebrew_paths.sh complete ==="