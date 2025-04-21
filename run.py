from flask import Flask, jsonify
from src.mediocremiles.strava_client import StravaClient


app = Flask(__name__)
strava_client = StravaClient()



@app.route("/")
def home():
    return "Welcome to MediocreMiles!"


@app.route("/activities", methods=["GET"])
def get_activities():
    """
    Fetches activities from Strava.
    """
    activities = strava_client
    return jsonify([activity.to_dict() for activity in activities]), 200


@app.route("/save_runs", methods=["POST"])
def save_runs():
    """
    Fetches run activities from Strava and saves them to a CSV file.
    """
    try:
        strava_client.save_run_activities_to_csv()
        return jsonify({"message": "Run activities saved successfully."}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True)
