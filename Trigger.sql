-- Trigger 1: Ensure only one location with Type = 'Head'
CREATE TRIGGER BeforeInsertLocation
BEFORE INSERT ON Location
FOR EACH ROW
BEGIN
    DECLARE existingHead INT;
    SELECT COUNT(*) INTO existingHead FROM Location WHERE Type = 'Head';
    IF NEW.Type = 'Head' AND existingHead > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only one "Head" location allowed.';
    END IF;
END;

-- Trigger 2: Ensure club member age is between 4 and 10 years
CREATE TRIGGER BeforeInsertAssignment1
BEFORE INSERT ON Assignment
FOR EACH ROW
BEGIN
    DECLARE clubMemberDOB DATE;
    DECLARE clubMemberAge INT;
    SELECT dateOfBirth INTO clubMemberDOB FROM Person WHERE personID = NEW.clubMemberID;
    SET clubMemberAge = TIMESTAMPDIFF(YEAR, clubMemberDOB, CURDATE());
    IF clubMemberAge < 4 OR clubMemberAge > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Club member age must be 4-10 years.';
    END IF;
END;

-- Trigger 3: Prevent multiple ongoing assignments for a club member
CREATE TRIGGER BeforeInsertAssignment2
BEFORE INSERT ON Assignment
FOR EACH ROW
BEGIN
    DECLARE ongoingAssignments INT;
    IF NEW.endDate IS NULL THEN
        SELECT COUNT(*) INTO ongoingAssignments FROM Assignment WHERE clubMemberID = NEW.clubMemberID AND endDate IS NULL;
        IF ongoingAssignments > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'End previous assignment before creating a new one.';
        END IF;
    END IF;
END;

-- Trigger 4: Ensure family member has an ongoing registration in Registered_At before assignment
CREATE TRIGGER BeforeInsertAssignment3
BEFORE INSERT ON Assignment
FOR EACH ROW
BEGIN
    IF NEW.endDate IS NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM Registered_At WHERE personID = NEW.familyMemberID AND endDate IS NULL AND locationID = NEW.locationID
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Family member must have ongoing registration.';
        END IF;
    END IF;
END;

-- Trigger 5: Ensure location capacity is not exceeded for active club members (ages 4-10)
CREATE TRIGGER BeforeInsertAssignmentCapacityCheck
BEFORE INSERT ON Assignment
FOR EACH ROW
BEGIN
    DECLARE currentActiveMembers INT;
    DECLARE locationCapacity INT;
    DECLARE memberDOB DATE;
    DECLARE memberAge INT;
    SELECT capacity INTO locationCapacity FROM Location WHERE locationID = NEW.LocationID;
    SELECT dateOfBirth INTO memberDOB FROM Person WHERE personID = NEW.clubMemberID;
    SET memberAge = TIMESTAMPDIFF(YEAR, memberDOB, CURDATE());
    IF memberAge BETWEEN 4 AND 10 THEN
        SELECT COUNT(*) INTO currentActiveMembers FROM Assignment A JOIN Person P ON A.clubMemberID = P.personID WHERE locationID = NEW.LocationID AND A.endDate IS NULL AND TIMESTAMPDIFF(YEAR, P.dateOfBirth, CURDATE()) BETWEEN 4 AND 10;
        IF currentActiveMembers + 1 > locationCapacity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location capacity exceeded.';
        END IF;
    END IF;
END;

-- Trigger 6: Prevent overlapping registrations for the same family member
CREATE TRIGGER BeforeInsertRegisteredAt
BEFORE INSERT ON Registered_At
FOR EACH ROW
BEGIN
    IF NEW.endDate IS NULL THEN
        IF EXISTS (SELECT 1 FROM Registered_At WHERE personID = NEW.personID AND endDate IS NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ongoing registration already exists.';
        END IF;
    END IF;
END;

-- Trigger 7: Prevent overlapping operation records for the same person
CREATE TRIGGER BeforeInsertOperates
BEFORE INSERT ON Operates
FOR EACH ROW
BEGIN
    IF NEW.endDate IS NULL THEN
        IF EXISTS (SELECT 1 FROM Operates WHERE personID = NEW.personID AND endDate IS NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ongoing operation record exists.';
        END IF;
    END IF;
END;

-- Trigger 8: Ensure only administrators can manage
CREATE TRIGGER BeforeInsertManages1
BEFORE INSERT ON Manages
FOR EACH ROW
BEGIN
    DECLARE personnelRole ENUM('Administrator', 'Trainer', 'Other');
    SELECT role INTO personnelRole FROM Personnel WHERE personID = NEW.personID;
    IF personnelRole <> 'Administrator' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only administrators can manage.';
    END IF;
END;

-- Trigger 9: Prevent multiple ongoing management records for the same person
CREATE TRIGGER BeforeInsertManages2
BEFORE INSERT ON Manages
FOR EACH ROW
BEGIN
    IF NEW.endDate IS NULL THEN
        IF EXISTS (SELECT 1 FROM Manages WHERE personID = NEW.personID AND endDate IS NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ongoing management record exists.';
        END IF;
    END IF;
END;

-- Trigger 10: Prevent scheduling two sessions at the same time and location
CREATE TRIGGER CheckDoubleBooking
BEFORE INSERT ON Sessions
FOR EACH ROW
BEGIN
    DECLARE existingCount INT;
    SELECT COUNT(*) INTO existingCount FROM Sessions WHERE sessionStartDateTime = NEW.sessionStartDateTime AND LocationID = NEW.LocationID AND sessionNum != NEW.sessionNum;
    IF existingCount > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Double booking detected.';
    END IF;
END;

-- Trigger 11: Ensure club member has an ongoing registration before joining a team
CREATE TRIGGER BeforeInsertApart_Of1
BEFORE INSERT ON Apart_Of
FOR EACH ROW
BEGIN
    DECLARE teamLocationID INT;
    SELECT locationID INTO teamLocationID FROM Formed_At WHERE teamName = NEW.teamName;
    IF NOT EXISTS (SELECT 1 FROM Assignment WHERE clubMemberID = NEW.personID AND endDate IS NULL AND locationID = teamLocationID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Club member must be registered at team location.';
    END IF;
END;

-- Trigger 12: Ensure the gender of the player matches the gender of the team
CREATE TRIGGER BeforeInsertApart_Of2
BEFORE INSERT ON Apart_Of
FOR EACH ROW
BEGIN
    DECLARE teamGender ENUM('Male','Female');
    DECLARE playerGender ENUM('Male','Female');
    SELECT gender INTO teamGender FROM Team WHERE teamName = NEW.teamName;
    SELECT gender INTO playerGender FROM ClubMember WHERE personID = NEW.personID;
    IF teamGender <> playerGender THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Teams must be gender-specific.';
    END IF;
END;

-- Trigger 13: Ensure a minimum of 3 hours between formations for the same player on the same day
CREATE TRIGGER BeforeInsertApart_Of3
BEFORE INSERT ON Apart_Of
FOR EACH ROW
BEGIN
    DECLARE conflictingSessions INT;
    SELECT COUNT(*) INTO conflictingSessions FROM Apart_Of WHERE personID = NEW.personID AND DATE(formationDateTime) = DATE(NEW.formationDateTime) AND ABS(TIMESTAMPDIFF(HOUR, formationDateTime, NEW.formationDateTime)) < 3;
    IF conflictingSessions > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Minimum 3-hour gap required between formations for the same player on the same day.';
    END IF;
END;

