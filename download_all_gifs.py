#!/usr/bin/env python3
"""
Download GIFs for ALL exercises from ExerciseDB RapidAPI.
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

# All exercises with search terms
ALL_EXERCISES = [
    # Push
    ("push_ups", "push up"),
    ("overhead_press", "overhead press"),
    ("bench_press", "bench press"),
    ("lateral_raises", "lateral raise"),
    ("front_raises", "front raise"),
    ("tricep_extension", "tricep extension"),
    ("db_chest_flys", "dumbbell fly"),
    ("tricep_rope_pushdown", "tricep pushdown"),
    ("rear_delt_fly", "rear delt"),
    # Pull
    ("lat_pulldown", "lat pulldown"),
    ("seated_row", "seated row"),
    ("pull_ups", "pull up"),
    ("bent_over_row", "bent over row"),
    ("deadlift", "deadlift"),
    ("db_pullovers", "pullover"),
    ("renegade_rows", "renegade row"),
    ("stiff_arm_pulldown", "straight arm pulldown"),
    ("rope_face_pull", "cable rear delt"),  # face pull alternative
    ("db_curls", "dumbbell biceps curl"),
    # Legs
    ("squat_variation", "squat"),
    ("hip_thrust", "hip thrust"),
    ("lunges", "lunge"),
    ("split_squats", "split squat"),
    ("split_stance_rdl", "romanian deadlift"),
    ("step_ups", "step up"),
    ("split_stance_hip_thrust", "glute bridge"),
    ("leg_extension", "leg extension"),
    ("leg_curl", "leg curl"),
    ("cable_kickbacks", "cable kickback"),
    ("abductions", "hip abduction"),
    ("calf_raises", "calf raise"),
]

OUTPUT_DIR = "Workout/Resources/ExerciseMedia"


def search_exercise(search_term: str) -> dict | None:
    url = f"https://exercisedb.p.rapidapi.com/exercises/name/{quote(search_term)}?limit=5"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        results = resp.json()
        return results[0] if results else None
    except Exception as e:
        print(f"  Search error: {e}")
        return None


def download_gif(exercise_id: str, output_path: str) -> bool:
    url = f"https://exercisedb.p.rapidapi.com/image?exerciseId={exercise_id}&resolution=360"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=30)
        resp.raise_for_status()
        if resp.headers.get('content-type', '').startswith('image'):
            with open(output_path, 'wb') as f:
                f.write(resp.content)
            return True
        return False
    except Exception as e:
        print(f"  Download error: {e}")
        return False


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Remove old MP4s
    for f in os.listdir(OUTPUT_DIR):
        if f.endswith('.mp4'):
            os.remove(os.path.join(OUTPUT_DIR, f))
            print(f"Removed old: {f}")

    print(f"\nDownloading GIFs for {len(ALL_EXERCISES)} exercises...\n")

    downloaded = []
    failed = []

    for filename, search_term in ALL_EXERCISES:
        output_path = os.path.join(OUTPUT_DIR, f"{filename}.gif")
        print(f"🔍 {filename}...")

        # Skip if already exists
        if os.path.exists(output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ⏭️  Already exists ({size_kb:.0f} KB)")
            downloaded.append(filename)
            continue

        # Search for exercise
        data = search_exercise(search_term)
        if not data:
            print(f"  ❌ Not found")
            failed.append((filename, search_term))
            time.sleep(0.5)
            continue

        exercise_id = data.get("id")
        matched_name = data.get("name")
        print(f"  ✓ Found: {matched_name} (ID: {exercise_id})")

        # Download GIF
        if download_gif(exercise_id, output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ✅ Saved ({size_kb:.0f} KB)")
            downloaded.append(filename)
        else:
            failed.append((filename, search_term))

        time.sleep(1)  # Rate limit

    # Summary
    print("\n" + "=" * 50)
    print(f"✅ Downloaded: {len(downloaded)}/31")
    if failed:
        print(f"❌ Failed: {len(failed)}")
        for name, term in failed:
            print(f"   - {name} (searched: {term})")

    print(f"\nTotal size: ", end="")
    total = sum(os.path.getsize(os.path.join(OUTPUT_DIR, f)) for f in os.listdir(OUTPUT_DIR) if f.endswith('.gif'))
    print(f"{total / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
