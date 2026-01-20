#!/usr/bin/env python3
"""
Download exercise videos from MuscleWiki API for the Workout app.
"""

import requests
import os
import time
from urllib.parse import quote

# Your exercises from ExerciseData.swift
EXERCISES = [
    # Push
    "Push Ups",
    "Overhead Press",
    "Bench Press",
    "Lateral Raises",
    "Front Raises",
    "Tricep Extension",
    "DB Chest Flys",
    "Tricep Rope Pushdown",
    "Rear Delt Fly",
    # Pull
    "Lat Pulldown",
    "Seated Row",
    "Pull Ups",
    "Bent Over Row",
    "Deadlift",
    "DB Pullovers",
    "Renegade Rows",
    "Stiff Arm Pulldown",
    "Rope Face Pull",
    "DB Curls",
    # Legs
    "Squat Variation",
    "Hip Thrust",
    "Lunges",
    "Split Squats",
    "Split Stance RDL",
    "Step Ups",
    "Split Stance Hip Thrust",
    "Leg Extension",
    "Leg Curl",
    "Cable Kickbacks",
    "Abductions",
    "Calf Raises",
]

# Map exercise names to better search terms for the API
SEARCH_TERMS = {
    "Push Ups": "push up",
    "Overhead Press": "overhead press",
    "Bench Press": "bench press",
    "Lateral Raises": "lateral raise",
    "Front Raises": "front raise",
    "Tricep Extension": "tricep extension",
    "DB Chest Flys": "dumbbell fly",
    "Tricep Rope Pushdown": "tricep pushdown",
    "Rear Delt Fly": "rear delt fly",
    "Lat Pulldown": "lat pulldown",
    "Seated Row": "seated row",
    "Pull Ups": "pull up",
    "Bent Over Row": "bent over row",
    "Deadlift": "deadlift",
    "DB Pullovers": "pullover",
    "Renegade Rows": "renegade row",
    "Stiff Arm Pulldown": "straight arm pulldown",
    "Rope Face Pull": "face pull",
    "DB Curls": "dumbbell curl",
    "Squat Variation": "squat",
    "Hip Thrust": "hip thrust",
    "Lunges": "lunge",
    "Split Squats": "split squat",
    "Split Stance RDL": "romanian deadlift",
    "Step Ups": "step up",
    "Split Stance Hip Thrust": "hip thrust",
    "Leg Extension": "leg extension",
    "Leg Curl": "leg curl",
    "Cable Kickbacks": "cable kickback",
    "Abductions": "hip abduction",
    "Calf Raises": "calf raise",
}

API_BASE = "https://workoutapi.vercel.app/exercises"
OUTPUT_DIR = "exercise_videos"


def search_exercise(name: str) -> dict | None:
    """Search for an exercise and return the first result."""
    search_term = SEARCH_TERMS.get(name, name.lower())
    url = f"{API_BASE}?name={quote(search_term)}"

    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        results = resp.json()

        if results and len(results) > 0:
            return results[0]
        return None
    except Exception as e:
        print(f"  Error searching for {name}: {e}")
        return None


def download_video(url: str, output_path: str) -> bool:
    """Download a video file."""
    # Remove timestamp from URL for download
    clean_url = url.split("#")[0]

    try:
        resp = requests.get(clean_url, timeout=30, stream=True)
        resp.raise_for_status()

        with open(output_path, "wb") as f:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)
        return True
    except Exception as e:
        print(f"  Error downloading: {e}")
        return False


def sanitize_filename(name: str) -> str:
    """Convert exercise name to valid filename."""
    return name.lower().replace(" ", "_").replace("/", "_")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    results = {"found": [], "not_found": [], "downloaded": [], "failed": []}

    print(f"Searching for {len(EXERCISES)} exercises...\n")

    for exercise in EXERCISES:
        print(f"🔍 {exercise}...")

        data = search_exercise(exercise)

        if not data:
            print(f"  ❌ Not found")
            results["not_found"].append(exercise)
            continue

        results["found"].append(exercise)

        # Get video URLs
        video_urls = data.get("videoURL", [])
        if not video_urls:
            print(f"  ⚠️  Found but no video URL")
            results["failed"].append(exercise)
            continue

        # Download front view (first video)
        video_url = video_urls[0]
        filename = f"{sanitize_filename(exercise)}.mp4"
        output_path = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(output_path):
            print(f"  ⏭️  Already downloaded")
            results["downloaded"].append(exercise)
            continue

        print(f"  ⬇️  Downloading...")
        if download_video(video_url, output_path):
            print(f"  ✅ Saved to {filename}")
            results["downloaded"].append(exercise)
        else:
            results["failed"].append(exercise)

        # Be nice to the API
        time.sleep(0.5)

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
