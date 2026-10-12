import os
import argparse
import snowflake.connector



def upload_files(args):
    conn = snowflake.connector.connect(
        user=args.snowflake_user,
        account=args.snowflake_account,
        role=args.snowflake_role,
        private_key_file=args.private_key_file,
        private_key_file_pwd=args.passphrase,
        database=args.snowflake_database,
        schema=args.snowflake_schema

    )

    cs = conn.cursor()
    try:
        streamlit_app_folder= 'streamlit/'+ args.folder_name
        
        print ('app folder path is '+ streamlit_app_folder)

        for root, dirs, files in os.walk(streamlit_app_folder):
            for file in files:
                file_path = os.path.join(root, file)
                with open(file_path, 'rb') as f:
                    file_contents = f.read()
                    cs.execute(f"PUT file://{file_path} @{args.internal_stage}/{args.folder_name} OVERWRITE = TRUE AUTO_COMPRESS = FALSE")
        
        
    finally:
        cs.close()
    conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Upload files to Snowflake')
    parser.add_argument('--snowflake_user', required=True, help='Snowflake user')
    parser.add_argument('--snowflake_account', required=True, help='Snowflake account')
    parser.add_argument('--snowflake_role', required=True, help='Snowflake role')
    parser.add_argument('--snowflake_private_key', required=True, help='Snowflake private key')
    parser.add_argument('--passphrase', required=True, help='Snowflake private key passphrase')
    parser.add_argument('--folder_name', required=True, help='Folder name containing files to upload')
    parser.add_argument('--private_key_file', required=True, help='Snowflake private key file')
    parser.add_argument('--snowflake_database', required=True, help='snowflake database')
    parser.add_argument('--snowflake_schema', required=True, help='snowflake schema')
    parser.add_argument('--internal_stage', required=True, help='internal stage')

    args = parser.parse_args()
    upload_files(args)

