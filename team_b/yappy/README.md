# yappy!

yappy! is an application that allows you to store transcripts of recorded audio created by Sherpa within the medical, restaurant, and mechanic industry contexts. These transcripts are then summarized via ChatGPT and parsed for relevant information in those respective industry contexts. Users can then search for specific transcripts and ask an AI assistant for more details about each industry's transcripts.

### Feature Overview
* Real-time speech-to-text conversion
* Speaker identification
* Industry-specific parsing (restaurant, mechanic, medical)
* Order identification and menu item validation (restaurant)
* Vehicle and part identification (mechanic)
* Visit summarization and question/answer extraction (medical)
* Interactive dashboard with role-based access
* Data export capabilities
* Order history review and customer preference tracking

## Getting Started with yappy!
Refer to the Programmer's Guide for additional detailed instructions on the structure of the codebase.
Refer to the Deployment and Operations Guide for environment setup and running yappy!
Refer to the User Guide for information about how users interact with yappy!

### Project File Structure Overview
* This project subfolder shall contain the standard Flutter project structure, initially generated using the `flutter new` command. 
* UI element code shall be placed in the root of the default “lib” folder. 
* Backend code shall be placed in a subfolder under “lib” named “services”. 
* Assets, including the icon pack, the database, and test documents shall be placed in the default “assets” folder.
* Unit tests and other UI testing code shall be placed within the default “test” folder.
* Android specific configurations shall be made under the default “android” folder.

### Database Setup SQL File
[yappy_sql_command_v1.1.txt](https://github.com/user-attachments/files/19398862/yappy_sql_command_v1.1.txt)
To update this file:
1. Delete current database in assets/ directory
2. Delete the database from the emulator (data/data/com.spring2025.yappy/databases/yappy_database.db) - only if the application has been run before
3. Update the SQL file as needed
4. Run SQL commands in a database integrated development environmnent (e.g. SQLite DB Browser)
5. Copy the updated database file to the assets/ directory
6. Update table creation methods and any associated queries in database_helper.dart

And remember, be **super** happy you have **yappy!**
