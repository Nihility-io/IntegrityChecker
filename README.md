# IntegrityChecker

Integrity Checker is a tool that checks for silent data corruption. Add all the folder you want to check to the tool and run it regularly.

Each time you run the check, Integrity Checker compares the current checksum of your files against the stored checksums. If an unexpected mismatch is found you should restore the file from a backup.

Checksums are stored in each files extended attributes.

### Note

I wrote this tool for my personal use. If it works for you as well use it. If it doesn't look for another tool.
