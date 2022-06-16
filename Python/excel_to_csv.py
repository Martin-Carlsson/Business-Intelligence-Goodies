# python3 -m venv .venv
# source .venv/bin/activate
# mkdir source_files output
# pip install pandas openpyxl

import pandas as pd

workbooks = ["workbook1", "workbook2"]
sheets = ["sheet1", "sheet2"]


for workbook in workbooks:
    for sheet in sheets:
        read_file = pd.read_excel(
            io="source_files/{}.xlsx".format(workbook), sheet_name=sheet
        )

        read_file["country"] = pd.Series(
            [workbook for x in range(len(read_file.index))]
        )

        read_file.to_csv(
            "output/{}_{}.csv".format(workbook, sheet), index=None, header=False
        )
