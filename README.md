# MontrealYouthSoccerClub-Database

## Overview
This project contains the SQL schema for the **Montreal Youth Soccer Club Database**, designed to manage various aspects of the club, including:
- Personal details of members, family members, and personnel.
- Location details and club locations.
- Membership, registration, and assignment details.
- Team management, sessions (training and games), and match play.
- Email logs for club communications.

The schema uses a combination of primary keys, foreign keys, and checks to enforce data integrity and model real-world relationships between entities.

## Database Structure
The schema includes the following tables:
- **Person:** Stores basic personal details.
- **LocationDetails:** Stores address and location information.
- **Lives_At:** Associates a person with their address.
- **FamilyMember, SecondaryFamilyMember:** Model family relationships.
- **Personnel:** Details for club personnel (administrators, trainers, etc.).
- **ClubMember:** Details for club members.
- **Location & Found_At:** Represent club locations and their addresses.
- **Assignment:** Tracks assignments between family members and club members.
- **Registered_At, Operates, Manages:** Track registration and operational roles.
- **Team, Sessions, Apart_Of, Plays, Formed_At:** Manage team formations, sessions, and game plays.
- **EmailLog:** Logs club email communications.

## How to Use
1. **Set Up Your Database:**
   - Ensure you have a MySQL or compatible database installed.
   - Run the provided `schema.sql` file in your database environment to create all tables.

2. **Extending the Schema:**
   - You can modify or extend the schema to add more functionalities as needed.
   - Consider creating additional indexes, views, or stored procedures to support application queries.

## Contributing
Contributions, suggestions, or improvements are welcome! Please fork the repository, make your changes, and open a pull request.
