#!/usr/bin/env python3
"""
Download remaining exercise GIFs from ExerciseDB RapidAPI.
"""

import requests
import os
import time

API_KEY = "8e74913321msh2681d810ff73ad7p141968jsn44537037ca5f"
HEADERS = {
    "x-rapidapi-host": "exercisedb.p.rapidapi.com",
    "x-rapidapi-key": API_KEY,
}

# Direct ID mappings for remaining exercises
EXERCISES_TO_DOWNLOAD = [
    ("db_curls", "0294"),  # dumbbell biceps curl
    ("rope_face_pull", "0203"),  # cable rear delt row with rope
    ("split_stance_hip_thrust", "1409"),  # barbell glute bridge
]

OUTPUT_DIR = "exercise_gifs"


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
        print(f"  Error: {e}")
        return False


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for filename, exercise_id in EXERCISES_TO_DOWNLOAD:
        output_path = os.path.join(OUTPUT_DIR, f"{filename}.gif")
        print(f"Downloading {filename} (ID: {exercise_id})...")

        if os.path.exists(output_path):
            print(f"  Already exists, skipping")
            continue

        if download_gif(exercise_id, output_path):
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  ✅ Saved ({size_kb:.0f} KB)")
        else:
            print(f"  ❌ Failed")

        time.sleep(1)

    print("\nDone! All GIFs:")
    for f in sorted(os.listdir(OUTPUT_DIR)):
        if f.endswith('.gif'):
            size = os.path.getsize(os.path.join(OUTPUT_DIR, f)) / 1024
            print(f"  {f} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
