-- Montreal Youth Soccer Club Database Schema
-- This schema defines the structure for managing club members,
-- personnel, family relationships, locations, team assignments,
-- sessions, and email logs for the Montreal Youth Soccer Club.

-- Table: Person
CREATE TABLE Person (
    personID INT PRIMARY KEY AUTO_INCREMENT,
    SSN CHAR(9) UNIQUE NOT NULL,
    firstName VARCHAR(50),
    lastName VARCHAR(50),
    medicareCardNumber VARCHAR(15) UNIQUE,
    dateOfBirth DATE NOT NULL,
    telephoneNumber VARCHAR(15),
    emailAddress VARCHAR(100)
);

-- Table: LocationDetails
CREATE TABLE LocationDetails (
    postalCode VARCHAR(10) PRIMARY KEY,
    city VARCHAR(50),
    province VARCHAR(50),
    address VARCHAR(255)
);

-- Table: Lives_At
CREATE TABLE Lives_At (
    personID INT,
    postalCode VARCHAR(10),
    PRIMARY KEY (personID),
    FOREIGN KEY (personID) REFERENCES Person(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (postalCode) REFERENCES LocationDetails(postalCode) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: FamilyMember
CREATE TABLE FamilyMember (
    personID INT PRIMARY KEY,
    FOREIGN KEY (personID) REFERENCES Person(personID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: Personnel
CREATE TABLE Personnel (
    personID INT PRIMARY KEY,
    role ENUM('Administrator', 'Trainer', 'Other') NOT NULL,
    mandate ENUM('Volunteer', 'Salary') NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person(personID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: ClubMember
CREATE TABLE ClubMember (
    personID INT PRIMARY KEY,
    clubMembershipID INT AUTO_INCREMENT UNIQUE NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person(personID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: SecondaryFamilyMember
CREATE TABLE SecondaryFamilyMember (
    primaryFamilyMemberID INT,
    secondaryFamilyMemberID INT,
    firstName VARCHAR(50),
    lastName VARCHAR(50),
    telephoneNumber VARCHAR(15) NOT NULL,
    PRIMARY KEY (primaryFamilyMemberID, secondaryFamilyMemberID),
    FOREIGN KEY (primaryFamilyMemberID) REFERENCES FamilyMember(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX (secondaryFamilyMemberID)
);

-- Table: Location
CREATE TABLE Location (
    locationID INT PRIMARY KEY AUTO_INCREMENT,
    locationName VARCHAR(100) NOT NULL,
    phoneNumber VARCHAR(15),
    webAddress VARCHAR(100),
    type ENUM('Head', 'Branch') NOT NULL,
    capacity INT CHECK (capacity > 0)
);

-- Table: Found_At
CREATE TABLE Found_At (
    locationID INT,
    postalCode VARCHAR(10),
    PRIMARY KEY (locationID),
    FOREIGN KEY (locationID) REFERENCES Location(locationID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (postalCode) REFERENCES LocationDetails(postalCode) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: Assignment
CREATE TABLE Assignment (
    familyMemberID INT NOT NULL,
    clubMemberID INT,
    secondaryID INT,
    LocationID INT,
    startDate DATE NOT NULL,
    endDate DATE DEFAULT NULL,
    primaryRelation ENUM('Father', 'Mother', 'GrandFather', 'GrandMother', 'Tutor', 'Partner', 'Friend', 'Other') NOT NULL,
    secondaryRelation ENUM('Father', 'Mother', 'GrandFather', 'GrandMother', 'Tutor', 'Partner', 'Friend', 'Other'),
    PRIMARY KEY (clubMemberID, startDate),
    FOREIGN KEY (familyMemberID) REFERENCES FamilyMember(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (clubMemberID) REFERENCES ClubMember(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (secondaryID) REFERENCES SecondaryFamilyMember(secondaryFamilyMemberID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (LocationID) REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (startDate <= endDate OR endDate IS NULL)
);

-- Table: Registered_At
CREATE TABLE Registered_At (
    personID INT,
    startDate DATE NOT NULL,
    endDate DATE DEFAULT NULL,
    CHECK (startDate <= endDate OR endDate IS NULL),
    locationID INT,
    PRIMARY KEY (personID, startDate),
    FOREIGN KEY (personID) REFERENCES FamilyMember(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (locationID) REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: Operates
CREATE TABLE Operates (
    personID INT,
    startDate DATE NOT NULL,
    endDate DATE DEFAULT NULL,
    CHECK (startDate <= endDate OR endDate IS NULL),
    locationID INT,
    PRIMARY KEY (personID, startDate),
    FOREIGN KEY (personID) REFERENCES Personnel(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (locationID) REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: Manages
CREATE TABLE Manages (
    personID INT,
    startDate DATE NOT NULL,
    endDate DATE DEFAULT NULL,
    CHECK (startDate <= endDate OR endDate IS NULL),
    locationID INT,
    PRIMARY KEY (personID, startDate),
    FOREIGN KEY (personID) REFERENCES Personnel(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (locationID) REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: Team
CREATE TABLE Team (
    teamName VARCHAR(50) PRIMARY KEY,
    headCoachID INT REFERENCES Personnel(personID) ON DELETE SET NULL ON UPDATE CASCADE,
    gender ENUM('Male', 'Female') NOT NULL
);

-- Table: Sessions
CREATE TABLE Sessions (
    sessionNum INT PRIMARY KEY AUTO_INCREMENT,
    sessionType ENUM('Training', 'Game') NOT NULL,
    team1Score INT NOT NULL,
    team2Score INT NOT NULL,
    sessionStartDateTime DATETIME NOT NULL,
    locationID INT REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: Apart_Of
CREATE TABLE Apart_Of (
    teamName VARCHAR(50),
    personID INT,
    role ENUM('Goalkeeper', 'Defender', 'Midfielder', 'Forward') NOT NULL,
    formationDateTime DATETIME NOT NULL,
    PRIMARY KEY (teamName, personID, formationDateTime),
    FOREIGN KEY (personID) REFERENCES ClubMember(personID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (teamName) REFERENCES Team(teamName) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: Plays
CREATE TABLE Plays (
    sessionNum INT,
    teamName1 VARCHAR(50) NOT NULL,
    teamName2 VARCHAR(50) NOT NULL,
    PRIMARY KEY (sessionNum),
    FOREIGN KEY (sessionNum) REFERENCES Sessions(sessionNum) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (teamName1) REFERENCES Team(teamName) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (teamName2) REFERENCES Team(teamName) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: Formed_At
CREATE TABLE Formed_At (
    teamName VARCHAR(50),
    locationID INT,
    PRIMARY KEY (teamName),
    FOREIGN KEY (teamName) REFERENCES Team(teamName) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (locationID) REFERENCES Location(locationID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table: EmailLog
CREATE TABLE EmailLog (
    emailNumber INT PRIMARY KEY AUTO_INCREMENT,
    sendDate DATETIME NOT NULL,
    emailSubject VARCHAR(255),
    emailBody VARCHAR(100),
    sender VARCHAR(100),
    receiver VARCHAR(100)
);
