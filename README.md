# MediocreMiles

**MediocreMiles** is a Python-based application that uses the [Strava API](https://developers.strava.com/) to retrieve, analyze, and visualize personal running data. Developed as a final project for **STAT 4580: Data Visualization** (Spring 2025), it provides accessible insights and exploratory visualizations for recreational runners without requiring advanced analytical tools.

For questions, please contact **Calvin McElvain** at [mcelvain@hotmail.com](mailto:mcelvain@hotmail.com).

---

## :rocket: Getting Started

### Prerequisites

- Python 3.8 or higher
- R (for the Shiny dashboard)
- A Strava account and API credentials (Client ID and Client Secret)
  - See [Strava's Getting Started Guide](https://developers.strava.com/docs/getting-started/)

### Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/mediocre-miles.git
    cd mediocre-miles
    ```

2. **Set up a Python virtual environment:**

    _Using the built-in venv:_

    ```bash
    python -m venv <environment_name>
    source <environment_name>/bin/activate
    ```

    _Or with Anaconda:_

    ```bash
    conda create -n <environment_name> python=3.8
    conda activate <environment_name>
    ```

3. **Install required Python dependencies:**

    ```bash
    pip install -r requirements.txt
    ```

4. **Configure API Credentials:**

    Create a `.env` file (e.g., in the project root) with the following contents:

    ```
    STRAVA_CLIENT_ID=your_client_id
    STRAVA_CLIENT_SECRET=your_client_secret
    ```

5. **Update Configuration Paths:**

    Ensure the configuration file ([configs/config.json](configs/config.json)) points to the correct locations for your environment (including the relative path to your `.env` file).

---

## :gear: Usage

### Python Data Processing

Fetch and process your Strava activity data using the main Python script. You can run the script with a variety of command-line options:

```bash
python run.py --days 30       # Fetch activities from the last 30 days
python run.py --all           # Fetch all available activities
python run.py --detailed      # Fetch detailed activity-level data after initial retrieval
python run.py --zones         # Export athlete heart rate/power zones
python run.py --athlete-stats # Export athlete summary statistics
```

Optionally, you can also specify a date before which activities should be fetched:

```bash
python run.py --before 2025-04-01  # Fetch activities before April 1, 2025
```

### R Shiny Dashboard

A Shiny dashboard is provided for interactive visualizations of your Strava activity data.

1. **Install R Packages**  
   Ensure the required R packages (e.g., shiny, shinydashboard, ggplot2, plotly, etc.) are installed. The dashboard uses packages installed from CRAN, so running the app from the project root (where the `global.R` file is located) will automatically install any missing packages.

2. **Launch the Dashboard:**

    In R or RStudio, set the working directory to the project root and run:

    ```r
    source("global.R")
    shinyApp(ui = appUI, server = appServer)
    ```

    Alternatively, you can run the app via the provided entry point file:

    ```r
    Rscript app.R
    ```

---

## :chart_with_upwards_trend: Project Scope

This project focuses on:

- **Trend Visualizations:** Plotting pace, heart rate, elevation, distance, and training load trends.
- **Performance Analysis:** Summarizing performance over time with interactive plots and summary statistics.
- **Predictive Insights:** Offering basic predictive analysis (e.g., forecasted pace or distance) using historical data.

All visualization and modeling components were developed and evaluated as part of the STAT 4580 course requirements.

---

## :white_check_mark: Completed Features

- **Strava API Integration:** Seamlessly retrieves activities and athlete data.
- **Local Data Storage:** Saves processed activity data for subsequent analysis.
- **Data Export:** Supports CSV and JSON formats.
- **Interactive Visualizations:** Generates plots and dashboards for pace trends, heart rate zones, power zones, and other performance Metrics.
- **Shiny Dashboard:** Provides an accessible web interface for exploring your running data.
- **Weather Data Integration:** Retrieves weather conditions for each activity using the [Meteostat Python library](https://github.com/meteostat/meteostat-python?tab=readme-ov-file) by matching the activity’s start date, time, and location.

---

## :page_facing_up: License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## :bookmark_tabs: Academic Note

This project was submitted as a final project for **STAT 4580: Data Visualization** in Spring 2025.
