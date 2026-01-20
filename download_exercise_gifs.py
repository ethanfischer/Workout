#!/usr/bin/env python3
"""
Download exercise GIFs from ExerciseDB RapidAPI for exercises missing videos.
"""

import requests
import os
import time
from urllib.parse import quote

API_KEY = "8e74913321msh2681d810ff73ad7p141968jsn44537037ca5f"
HEADERS = {
    "x-rapidapi-host": "exercisedb.p.rapidapi.com",
    "x-rapidapi-key": API_KEY,
}

# Exercises that currently have static images (need GIFs)
MISSING_EXERCISES = [
    ("Push Ups", "push up"),
    ("Lateral Raises", "lateral raise"),
    ("Front Raises", "front raise"),
    ("DB Chest Flys", "dumbbell fly"),
    ("Tricep Rope Pushdown", "tricep pushdown"),
    ("Rear Delt Fly", "rear delt"),
    ("Lat Pulldown", "lat pulldown"),
    ("Seated Row", "seated row"),
    ("DB Pullovers", "pullover"),
    ("Stiff Arm Pulldown", "straight arm pulldown"),
    ("Rope Face Pull", "face pull"),
    ("DB Curls", "dumbbell curl"),
    ("Hip Thrust", "hip thrust"),
    ("Lunges", "lunge"),
    ("Split Squats", "split squat"),
    ("Split Stance RDL", "romanian deadlift"),
    ("Step Ups", "step up"),
    ("Split Stance Hip Thrust", "single leg hip thrust"),
    ("Cable Kickbacks", "cable kickback"),
    ("Abductions", "hip abduction"),
]

OUTPUT_DIR = "exercise_gifs"


def search_exercise(search_term: str) -> dict | None:
    """Search for an exercise and return the best match."""
    url = f"https://exercisedb.p.rapidapi.com/exercises/name/{quote(search_term)}?limit=10"

    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        results = resp.json()

        if results and len(results) > 0:
            # Return the first result (best match)
            return results[0]
        return None
    except Exception as e:
        print(f"  Error searching: {e}")
        return None


def download_gif(exercise_id: str, output_path: str) -> bool:
    """Download a GIF for the given exercise ID."""
    url = f"https://exercisedb.p.rapidapi.com/image?exerciseId={exercise_id}&resolution=360"

    try:
        resp = requests.get(url, headers=HEADERS, timeout=30)
        resp.raise_for_status()

        # Check if we got a GIF
        if resp.headers.get('content-type', '').startswith('image'):
            with open(output_path, 'wb') as f:
                f.write(resp.content)
            return True
        else:
            print(f"  Unexpected content type: {resp.headers.get('content-type')}")
            return False
    except Exception as e:
        print(f"  Error downloading: {e}")
        return False


def sanitize_filename(name: str) -> str:
    """Convert exercise name to valid filename."""
    return name.lower().replace(" ", "_").replace("/", "_")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    results = {"downloaded": [], "not_found": [], "failed": []}

    print(f"Downloading GIFs for {len(MISSING_EXERCISES)} exercises...\n")

    for exercise_name, search_term in MISSING_EXERCISES:
        print(f"🔍 {exercise_name}...")

        # Search for the exercise
        data = search_exercise(search_term)

        if not data:
            print(f"  ❌ Not found")
            results["not_found"].append(exercise_name)
            time.sleep(0.5)
            continue

        exercise_id = data.get("id")
        matched_name = data.get("name")
        print(f"  ✓ Found: {matched_name} (ID: {exercise_id})")

        # Download the GIF
        filename = f"{sanitize_filename(exercise_name)}.gif"
        output_path = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(output_path):
            print(f"  ⏭️  Already exists")
            results["downloaded"].append(exercise_name)
            continue

        print(f"  ⬇️  Downloading GIF...")
        if download_gif(exercise_id, output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ✅ Saved ({size_kb:.0f} KB)")
            results["downloaded"].append(exercise_name)
        else:
            results["failed"].append(exercise_name)

        # Rate limiting
        time.sleep(1)

    # Summary
    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    print(f"✅ Downloaded: {len(results['downloaded'])}")
    print(f"❌ Not found:  {len(results['not_found'])}")
    print(f"⚠️  Failed:     {len(results['failed'])}")

    if results["not_found"]:
        print(f"\nNot found: {', '.join(results['not_found'])}")

    if results["failed"]:
        print(f"\nFailed: {', '.join(results['failed'])}")


if __name__ == "__main__":
    main()
