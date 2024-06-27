
# Import Necessary Packages
import pandas as pd
import numpy as np
import hashlib

# Create function that cleans dataset in new data analysis notebook.
def get_cleaned_df():
    
    # Load Data
    payroll = pd.read_csv('Payroll.csv')

    # Define string columns to target for cleaning
    string_cols = ['Agency Name', 'Last Name','First Name', 
               'Mid Init', 'Agency Start Date', 'Work Location Borough',
               'Title Description', 'Leave Status as of June 30','Pay Basis']

    # Strip extra spaces and uppercase all string columns
    for col in string_cols:
        payroll[col] = payroll[col].str.strip().str.upper()

    # Because other options for filling nulls in the borough column proved too memory intensive, filling them with "WITHHELD" is the best option. 
    payroll['Work Location Borough'].fillna('WITHHELD',inplace=True)

    # Create a list of appropriate borough options
    boroughs = ['BROOKLYN', 'MANHATTAN', 'BRONX', 'RICHMOND', 'QUEENS','WESTCHESTER', 'NASSAU', 'ORANGE','PUTNAM', 'WITHHELD']

    # Replace all non-WITHHELD locations that are not NYC boroughs with OTHER
    payroll['Work Location Borough'] = np.where(payroll['Work Location Borough'].isin(boroughs),
                                                payroll['Work Location Borough'],
                                                'OTHER')
    
    # Identifying information (names) for some job titles have been removed for the safety and protection of the individuals filling those job posts. 
    # Because I want to generate IDs for each person, however, I need to have something in those columns. X will suffice. 
    payroll['First Name'].fillna('X', inplace=True)
    payroll['Last Name'].fillna('X', inplace=True)

    # Because Title Description and Agency Start Date will form part of the Worker ID, I need something in those columns as well. 
    # However, since only 63 start dates and only 96 title descriptions are missing out of a dataset of 5,000,000 rows, it's okay to drop them. 
    payroll.dropna(subset=['Agency Start Date','Title Description'], inplace=True)

    # Function to generate worker ID 
    def generate_custom_worker_id(row, id_dict, count_dict):
        # Take the first letter of the first and last names
        first_initial = row['First Name'][0]
        last_initial = row['Last Name'][0]
    
        # Take the first letters of each word in the job title
        job_title_initials = ''.join([word[0] for word in row['Title Description'].split()])
    
        # Use the start date
        start_date = row['Agency Start Date'].replace('/', '').replace('-','')
    
        # Create a unique key based on the relevant fields
        unique_key = (first_initial, last_initial, job_title_initials, start_date)
    
        # Base ID without any counter
        base_id = f"{first_initial}{last_initial}{job_title_initials}_{start_date}"
    
        # Check if the unique key is already in the dictionary
        if unique_key not in id_dict:
            if base_id not in count_dict:
                count_dict[base_id] = 1
            else:
                count_dict[base_id] += 1
        
            worker_id = f"{base_id}_{count_dict[base_id]}" if count_dict[base_id] > 1 else base_id
            id_dict[unique_key] = worker_id
        else:
            worker_id = id_dict[unique_key]
    
        return worker_id

    # Dictionaries to keep track of generated IDs and counts for each unique combination
    id_dict = {}
    count_dict = {}

    # Apply the function to each row to create the 'Worker ID' column
    payroll['Worker ID'] = payroll.apply(lambda row: generate_custom_worker_id(row, id_dict, count_dict), axis=1)

    # Convert Agency Start Date to pandas date time for easy use in SQL
    # Drop Errors and nulls
    payroll['Agency Start Date'] = pd.to_datetime(payroll['Agency Start Date'], errors='coerce')
    payroll.dropna(subset=['Agency Start Date'], inplace=True)

    # Drops Payroll Number because it is just a numerical category of Agency Name and has missings where Agency Name does not. 
    # Drops identity information because it is irrelevant and unethical to use. 
    drop_columns = ['Payroll Number','Last Name','First Name','Mid Init']
    payroll.drop(columns = drop_columns, inplace=True)

    # Set new column order
    column_order = ['Worker ID','Fiscal Year', 'Agency Name', 'Agency Start Date',
       'Work Location Borough', 'Title Description',
       'Leave Status as of June 30', 'Base Salary', 'Pay Basis',
       'Regular Hours', 'Regular Gross Paid', 'OT Hours', 'Total OT Paid',
       'Total Other Pay']
    
    # Apply new column order
    payroll = payroll[column_order]

    # Reset Index
    payroll.reset_index(drop=True, inplace=True)

    # Add a true index column
    payroll.reset_index(drop=False, inplace=True)

    # Rename the new index column if needed
    payroll.rename(columns={'index': 'True Index'}, inplace=True)

    # Define a function to convert pay based on pay basis
    def convert_pay(row):
        if row['Pay Basis'] == 'per Day':
            return row['Base Salary'] * 365
        elif row['Pay Basis'] == 'per Hour':
            return row['Base Salary'] * 40 * 48
        else:
            return row['Base Salary']

    # Apply the function to each row to create the 'Converted Pay' column
    payroll['Converted Salary'] = payroll.apply(convert_pay, axis=1)

    # Calculate the sum of the specified columns and create the 'Total Pay' column
    payroll['Total Pay'] = payroll[['Regular Gross Paid', 'Total OT Paid', 'Total Other Pay']].sum(axis=1)

    # Convert column names to be more python and sql friendly
    payroll.columns = payroll.columns.str.strip().str.lower().str.replace(' ','_')
    
    # Set new column order
    columns_order = ['worker_id', 'fiscal_year', 'agency_name',
       'agency_start_date', 'work_location_borough', 'title_description',
       'leave_status_as_of_june_30', 'base_salary', 'pay_basis',
       'regular_hours', 'regular_gross_paid', 'ot_hours', 'total_ot_paid',
       'total_other_pay', 'converted_salary', 'total_pay','true_index']
    
    # apply new column order
    payroll = payroll[columns_order]
    
    # Saves cleaned data as csv file for use in other programs
    payroll.to_csv('cleaned_payroll.csv', index=False)

    return payroll



