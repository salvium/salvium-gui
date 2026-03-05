"""
Optional helper for P2Pool binary verification.

Current GUI flow downloads binaries from:
https://github.com/mxhess/p2pool-salvium/releases

Automatic verification in CI is intentionally disabled. To enable this helper:
1) implement the checks you want (e.g. compare against sha256sums.txt),
2) uncomment the command in `.github/workflows/verify_p2pool.yml`.
"""


def main() -> None:
    print("P2Pool binary verification is disabled by default.")
    print("Release source: https://github.com/mxhess/p2pool-salvium/releases")


if __name__ == "__main__":
    main()
