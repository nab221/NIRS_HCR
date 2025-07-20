# NIRS & HCR Analysis Tool

This repository contains a MATLAB-based application for the analysis and visualisation of Near-Infrared Spectroscopy (NIRS) and Hand-Clench Relaxometer (HCR) data. This tool provides a graphical user interface (GUI) to streamline data import, filtering, interactive segment selection, and the calculation of key physiological metrics.

## Citation

If you use this software in your research, please cite our publication:

**[Publication link]**

## Output Metrics

The application calculates the following metrics:

  * **NIRS Analysis:**
      * **Nadir:** The lowest point of TSI during exercise, reported as a percentage reduction from baseline and the time taken to reach it.
      * **Mean Reduction:** The average percentage reduction in TSI throughout the exercise segment.
      * **TSI & Total Hb AUC:** The Area Under the Curve (cumulative sum) for both TSI and Total Hemoglobin, calculated at 30-second intervals (30s, 60s, 90s, 120s, 150s, 180s).
      * **Recovery Times:** T50 (time to 50% recovery) and T100 (time to return to baseline) are calculated for the recovery period.
  * **HCR Analysis:**
      * **HCR AUC:** The Area Under the Curve (cumulative sum) of the HCR power signal, reported at 30-second intervals.
      * **Time on Target:** The amount of time the user's force output remained within the target zone (35-45% of max power), calculated for 30-second intervals.

## Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/nirs_hcr.git
    ```
2.  **MATLAB:** This application requires **MATLAB** to be installed.
3.  **Oxysoft to MATLAB Conversion (Optional):**
    If you need to convert `.oxy` files, you must install the `oxysoft2matlab` function. A version of this function can be found at [https://github.com/jayd1860/oxysoft2matlab](https://github.com/jayd1860/oxysoft2matlab). Please follow the instructions provided there to add this function to your MATLAB path.

## Quick Start Guide

1.  **Launch the App:** Open MATLAB, navigate to the cloned repository's directory, and run `NIRS_HCR.m`. The main application window will open.
2.  **Convert or Load NIRS Data:**
      * **Convert (First-time use):** Click the **Convert** icon. Select your `.oxy` data file and the corresponding `.oxyproj` project file. The converted `.mat` file will be saved and automatically loaded.
      * **Load:** Click the **Open** icon to load a `.mat` file containing NIRS data or a previously saved session.
3.  **Load HCR Data:** Click the **Load HCR** icon to import HCR data from a `.csv` or text file.
4.  **Select Segments:**
      * In the "Select segments" panel, click the **Baseline** button. Your cursor will change; click twice on the TSI plot (`ax2`) to define the start and end of the baseline period.
      * Click the **Exercise** button and similarly select the exercise period on the TSI plot. The recovery period will be automatically defined from the end of the exercise to the end of the recording.
5.  **Analyze Data:**
      * As soon as the baseline and exercise segments are selected, NIRS metrics (Nadir, Mean Reduction, AUC, Recovery) are automatically calculated and displayed on the right-hand panel.
      * For HCR analysis, ensure the correct **Max Power (N)** is set, then click **Calculate\!** to update the "Time on Target" metrics.
6.  **Save Results:**
      * **Save Session:** Click the **Save** icon to save all data, plots, and segment selections to a `.mat` file.
      * **Export to CSV:** Click the **Save to CSV** icon. This appends all calculated metrics for the current dataset to a CSV file of your choice.

## Contributing

We welcome contributions\! Please feel free to submit a pull request or open an issue for any bugs or feature requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

Copyright (c) 2025 Dr Anderson Brito da Silva/Newcastle University# NIRS & HCR Analysis Tool
