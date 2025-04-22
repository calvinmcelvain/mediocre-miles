# MediocreMiles

**MediocreMiles** is a Python-based application using [Strava's API](https://developers.strava.com/) designed to analyze and visualize individual running data. The goal is to provide accessible insights and predictive analysis for personal running performance—without requiring professional-level athleticism or expertise.

For inquiries, please contact **Calvin McElvain** at [mcelvain@hotmail.com](mailto:mcelvain@hotmail.com).

---

## :rocket: Getting Started

### Prerequisites

- Python 3.8+
- A Strava account
- Strava API credentials (Client ID & Secret)

### Installation

1. Clone the repository

```bash
git clone https://github.com/your-username/mediocre-miles.git
cd mediocre-miles
```

2. Install dependencies

```bash
pip install -r requirements.txt
```

3. Set up your environment variables in `.env`:

```
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
```

### Usage

Run the main script to fetch your Strava activities:

```bash
python run.py --days 30  # Fetch last 30 days of activities
python run.py --all     # Fetch all activities
```

---

## :chart_with_upwards_trend: Purpose

MediocreMiles aims to help users:

- Understand their running habits and performance trends through visualizations.
- Identify patterns over time (e.g., pace improvements, training frequency).
- Generate basic predictive analytics based on historical data (e.g., forecasted pace, distance progression).

---

## :round_pushpin: Current Status & Roadmap

### Completed

- [X] Strava API integration.
- [X] Activity data fetching and storage.
- [X] Basic CSV export functionality.

### In Progress

- [ ] Visual analytics: pace trends, HR trends, distance over time, elevation profiles.
- [ ] Predictive models for future performance metrics.
- [ ] Route-based breakdowns and geospatial insights.

### Future Plans: Workout Parser

The next major feature will focus on intelligent workout parsing:
- Integration with LLMs to parse unstructured workout data.
- Move beyond fixed-interval workout tracking limitations.
- Develop smarter analysis using both statistical methods and AI.

---

## :memo: Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## :page_facing_up: License

This project is licensed under the MIT License. See the `LICENSE` file for details.
