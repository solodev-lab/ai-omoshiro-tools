"""
Overnight batch: generate leo, pisces, scorpio, virgo variants sequentially.
Slow pace, with 503 auto-retry. ~1.5-2 hours total.
"""
import subprocess
import sys
import time
from pathlib import Path

BASES = ["leo", "pisces", "scorpio", "virgo"]
SCRIPT = Path(__file__).parent / "generate_base_variants.py"


def main():
    print(f"=== Overnight batch: {len(BASES)} bases × 11 variants = {len(BASES)*11} images ===\n")
    overall_start = time.time()

    for idx, base in enumerate(BASES, 1):
        print(f"\n{'='*60}")
        print(f"  [{idx}/{len(BASES)}] Base: {base}")
        print(f"{'='*60}")
        start = time.time()

        result = subprocess.run(
            [sys.executable, str(SCRIPT), base],
            capture_output=False,
        )
        elapsed = int(time.time() - start)
        print(f"\n  [{base}] finished in {elapsed//60}m{elapsed%60}s (exit={result.returncode})")

        # Longer pause between bases to cool down API
        if idx < len(BASES):
            cooldown = 30
            print(f"\n  Cooling down {cooldown}s before next base...")
            time.sleep(cooldown)

    total = int(time.time() - overall_start)
    print(f"\n{'='*60}")
    print(f"=== ALL DONE in {total//60}m{total%60}s ===")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
