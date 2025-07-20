# NIRS & HCR Analysis Tool

This repository contains a MATLAB-based application for the analysis and visualisation of Near-Infrared Spectroscopy (NIRS) and Hand-Clench Relaxometer (HCR) data as seen in **[Publication link]**. This is a graphical user interface to streamline the process of data import, segment selection and calculation of key metrics.

## Citation

If you use this software in your research, please cite our publication:

**[Publication link]**

## Installation

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/your-username/nirs_hcr.git
    ```

2.  **MATLAB:** This application requires **MATLAB** to be installed.

3.  **Oxysoft to MATLAB Conversion (Optional):**
    If you need to convert `.oxy` files, you must install the `oxysoft2matlab` function. A version of this function can be found at [https://github.com/jayd1860/oxysoft2matlab](https://github.com/jayd1860/oxysoft2matlab). Please follow the instructions provided there, or the official Oxysoft guide for adding this function to your MATLAB path.

## Quick Start Guide

1.  **Launch the App:** Open MATLAB, navigate to the cloned repository's directory, and run `NIRS_HCR.m`. The main application window will open.

2.  **Convert Data (if needed):**

      * Click the **Convert** icon in the toolbar.
      * Select your `.oxy` data file and the corresponding `.oxyproj` project file.
      * Choose a location to save the converted `.mat` file.
      * The converted data will automatically load into the app.

3.  **Load Data:**

      * **NIRS Data:** Click the **Open** icon to load a `.mat` file containing your NIRS data.
      * **HCR Data:** Click the **Load HCR** icon to import HCR data from a `.csv` or text file.

4.  **Select Segments:**

      * On the "Select segments" panel, click **Baseline**, **Exercise**, or **Recovery**.
      * Your cursor will change. Click twice on the TSI plot (`ax2`) to define the start and end of the segment.

5.  **Analyze Data:**

      * Once baseline and exercise segments are selected, NIRS metrics will be calculated and displayed.
      * For HCR analysis, set the **Max Power (N)** and click **Calculate\!**. The "Time on Target" values will be updated.

6.  **Save Results:**

      * **Save Session:** Click the **Save** icon to save all current data and selections to a `.mat` file for later use.
      * **Export to CSV:** Click the **Save to CSV** icon. This will append the calculated metrics for the current dataset to a `.csv` file, allowing you to aggregate results from multiple sessions.

## Contributing

We welcome contributions\! Please feel free to submit a pull request or open an issue for any bugs or feature requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
