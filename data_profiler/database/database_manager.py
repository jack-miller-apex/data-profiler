'''
Jack Miller
Apex Companies
June 2024
'''

import pyodbc
from pyodbc import Connection
from cryptography.fernet import Fernet

from apex_gui.frames.notification_dialogs import CriticalErrorDialog


class DatabaseConnection():
    '''
    Manages connection with aasdevfree Azure SQL database. Use in "with" block to receive a pyodbc Connection object
    '''
    
    def __init__(self, dev: bool = False) -> Connection:
        self.dev = dev

    def __enter__(self) -> Connection:
        self.connection_string = self._get_connection_string()
        
        try:
            self.connection = self._create_server_connection()
        except pyodbc.InterfaceError as e:
            error_dialog = CriticalErrorDialog(title='Data Profiler', text=f'CRITICAL:\n\nCould not connect to database. Please quit the application and try again.')
            error_dialog.mainloop()
            raise e
        else:
            return self.connection

    def __exit__(self, exception_type, exception_value, exception_traceback):
        if exception_type is None:
            self.connection.close()
        else:
            print(f'{exception_type = }\n{exception_value = }\n{exception_traceback = }\n')
            self.connection.close()
            raise exception_value
        
    # Use Fernet cipher to decrypt connection string
    # https://cryptography.io/en/latest/
    def _get_connection_string(self):
        key = open('Y:\\Database\\Writer\\SECRET-key.txt').read()
        suite = Fernet(key)
        
        cxn_str = open('Y:\\Database\\Writer\\SECRET-sql-connection-string.txt').read()
        connection_string = suite.decrypt(cxn_str).decode()

        return connection_string

    # Creates and returns a SQL Server connection to Apex database
    def _create_server_connection(self, retries: int = 5) -> Connection:        
        # ----- Resilience: if connection isn't successful the first time, try again. Important because the Azure SQL database tends to be slow on first start up ----- 
        tries = 0
        successful_connection = False
        while not successful_connection and tries < retries:
            print(f'Connecting to DB, attempt {tries}')
            try:
                connection = pyodbc.connect(self.connection_string, timeout=15)
                # connection = pyodbc.connect('bas')
                connection.cursor()
            except pyodbc.Error as err:
                continue
            else:
                successful_connection = True
            finally:
                tries += 1

        if not successful_connection:
            raise pyodbc.InterfaceError('Could not connect to database.')
        
        return connection
    