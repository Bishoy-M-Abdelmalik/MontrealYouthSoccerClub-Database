-- Procedure to log emails for past sessions
CREATE PROCEDURE PopulateEmailLogForPastSessions()
BEGIN
    -- Declare variables for session details
    DECLARE done INT DEFAULT 0;
    DECLARE sessionNum INT;
    DECLARE sessionType VARCHAR(10);
    DECLARE sessionStartDateTime DATETIME;
    DECLARE locationName VARCHAR(100);
    DECLARE locationAddress VARCHAR(255);
    DECLARE locationCity VARCHAR(50);
    DECLARE locationProvince VARCHAR(50);
    DECLARE locationPostalCode VARCHAR(10);
    DECLARE teamName1 VARCHAR(50);
    DECLARE teamName2 VARCHAR(50);
    DECLARE headCoach1FirstName VARCHAR(50);
    DECLARE headCoach1LastName VARCHAR(50);
    DECLARE headCoach1Email VARCHAR(100);
    DECLARE headCoach2FirstName VARCHAR(50);
    DECLARE headCoach2LastName VARCHAR(50);
    DECLARE headCoach2Email VARCHAR(100);
    
    -- Declare variables for member details
    DECLARE clubMembershipID INT;
    DECLARE clubMemberFirstName VARCHAR(50);
    DECLARE clubMemberLastName VARCHAR(50);
    DECLARE clubMemberEmail VARCHAR(100);
    DECLARE role ENUM('Goalkeeper', 'Defender', 'Midfielder', 'Forward');
    DECLARE memberTeamName VARCHAR(50);
    
    -- Declare variables for email content
    DECLARE emailSubject VARCHAR(255);
    DECLARE emailBody TEXT;
    DECLARE receiver VARCHAR(100);

    -- Cursor to fetch past session details
    DECLARE session_cursor CURSOR FOR 
    SELECT S.sessionNum, S.sessionType, S.sessionStartDateTime, 
           L.locationName, LD.address, LD.city, LD.province, LD.postalCode, 
           T1.teamName, T2.teamName, 
           P1.firstName, P1.lastName, P1.emailAddress, 
           P2.firstName, P2.lastName, P2.emailAddress
    FROM Sessions S
    JOIN Location L ON S.locationID = L.locationID
    JOIN Found_At FA ON L.locationID = FA.locationID
    JOIN LocationDetails LD ON FA.postalCode = LD.postalCode
    JOIN Plays ply ON ply.sessionNum = S.sessionNum
    JOIN Team T1 ON ply.teamName1 = T1.teamName
    JOIN Team T2 ON ply.teamName2 = T2.teamName
    JOIN Person P1 ON T1.headCoachID = P1.personID
    JOIN Person P2 ON T2.headCoachID = P2.personID
    WHERE S.sessionStartDateTime < CURDATE()
    ORDER BY S.sessionStartDateTime;

    -- Continue handler for cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open session cursor
    OPEN session_cursor;

    -- Loop through each session
    session_loop: LOOP
        FETCH session_cursor INTO sessionNum, sessionType, sessionStartDateTime, 
                              locationName, locationAddress, locationCity, locationProvince, locationPostalCode, 
                              teamName1, teamName2, 
                              headCoach1FirstName, headCoach1LastName, headCoach1Email, 
                              headCoach2FirstName, headCoach2LastName, headCoach2Email;

        IF done THEN 
            LEAVE session_loop;
        END IF;

        -- Open nested block for member processing
        BEGIN
            DECLARE done_members INT DEFAULT 0;
            
            -- Cursor to fetch members associated with teams
            DECLARE member_cursor CURSOR FOR 
            SELECT CM.clubMembershipID, P.firstName, P.lastName, P.emailAddress, AO.role, AO.teamName
            FROM Apart_Of AO
            JOIN ClubMember CM ON AO.personID = CM.personID
            JOIN Person P ON CM.personID = P.personID
            WHERE AO.teamName IN (teamName1, teamName2);

            -- Continue handler for member cursor
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_members = 1;

            -- Open member cursor
            OPEN member_cursor;

            -- Loop through each club member
            member_loop: LOOP
                FETCH member_cursor INTO clubMembershipID, clubMemberFirstName, clubMemberLastName, 
                                      clubMemberEmail, role, memberTeamName;

                IF done_members THEN 
                    LEAVE member_loop;
                END IF;

                -- Construct email subject
                SET emailSubject = CONCAT(teamName1, ' vs ', teamName2, ' on ', 
                                          DATE_FORMAT(sessionStartDateTime, '%d-%b-%Y %l:%i %p'), 
                                          ' ', sessionType, ' session');

                -- Construct email body based on member’s team
                IF memberTeamName = teamName1 THEN
                    SET emailBody = CONCAT('Dear ', clubMemberFirstName, ' ', clubMemberLastName, ',\n\n',
                                           'You participated in a ', sessionType, ' session on ', 
                                           DATE_FORMAT(sessionStartDateTime, '%W, %M %d, %Y'), ' at ', 
                                           DATE_FORMAT(sessionStartDateTime, '%l:%i %p'), '.\n',
                                           'Location: ', locationAddress, ', ', locationCity, ', ', locationProvince, ', ', locationPostalCode, '\n\n',
                                           'Your role: ', role, '\n',
                                           'Head Coach: ', headCoach1FirstName, ' ', headCoach1LastName, ' (Email: ', headCoach1Email, ')\n',
                                           'Best regards,\n',
                                           'Your Team Management');
                ELSE
                    SET emailBody = CONCAT('Dear ', clubMemberFirstName, ' ', clubMemberLastName, ',\n\n',
                                           'You participated in a ', sessionType, ' session on ', 
                                           DATE_FORMAT(sessionStartDateTime, '%W, %M %d, %Y'), ' at ', 
                                           DATE_FORMAT(sessionStartDateTime, '%l:%i %p'), '.\n',
                                           'Location: ', locationAddress, ', ', locationCity, ', ', locationProvince, ', ', locationPostalCode, '\n\n',
                                           'Your role: ', role, '\n',
                                           'Head Coach: ', headCoach2FirstName, ' ', headCoach2LastName, ' (Email: ', headCoach2Email, ')\n',
                                           'Best regards,\n',
                                           'Your Team Management');
                END IF;

                -- Set receiver email
                SET receiver = clubMemberEmail;

                -- Insert email log entry
                INSERT INTO EmailLog (sendDate, emailSubject, emailBody, sender, receiver) 
                VALUES (NOW(), emailSubject, LEFT(emailBody, 100), locationName, receiver);

            END LOOP;

            -- Close member cursor
            CLOSE member_cursor;

        END;

    END LOOP;

    -- Close session cursor
    CLOSE session_cursor;
END;


CREATE PROCEDURE SendWeeklySessionEmails()
BEGIN
    -- Declare session cursor variables
    DECLARE done INT DEFAULT 0;
    DECLARE sessionNum INT;
    DECLARE sessionType VARCHAR(10);
    DECLARE sessionStartDateTime DATETIME;
    DECLARE locationName VARCHAR(100);
    DECLARE locationAddress VARCHAR(255);
    DECLARE locationCity VARCHAR(50);
    DECLARE locationProvince VARCHAR(50);
    DECLARE locationPostalCode VARCHAR(10);
    DECLARE teamName1 VARCHAR(50);
    DECLARE teamName2 VARCHAR(50);
    DECLARE headCoach1FirstName VARCHAR(50);
    DECLARE headCoach1LastName VARCHAR(50);
    DECLARE headCoach1Email VARCHAR(100);
    DECLARE headCoach2FirstName VARCHAR(50);
    DECLARE headCoach2LastName VARCHAR(50);
    DECLARE headCoach2Email VARCHAR(100);
    
    -- Declare variables for email content
    DECLARE emailSubject VARCHAR(255);
    DECLARE emailBody TEXT;
    DECLARE receiver VARCHAR(100);

    -- Declare club member cursor variables
    DECLARE clubMembershipID INT;
    DECLARE clubMemberFirstName VARCHAR(50);
    DECLARE clubMemberLastName VARCHAR(50);
    DECLARE clubMemberEmail VARCHAR(100);
    DECLARE role ENUM('Goalkeeper', 'Defender', 'Midfielder', 'Forward');
    DECLARE memberTeamName VARCHAR(50);

    -- Declare a cursor to fetch upcoming sessions within the next 7 days
    DECLARE session_cursor CURSOR FOR 
    SELECT 
        S.sessionNum, S.sessionType, S.sessionStartDateTime, 
        L.locationName, LD.address, LD.city, LD.province, LD.postalCode, 
        T1.teamName, T2.teamName, 
        P1.firstName, P1.lastName, P1.emailAddress, 
        P2.firstName, P2.lastName, P2.emailAddress
    FROM Sessions S
    JOIN Location L ON S.locationID = L.locationID
    JOIN Found_At FA ON L.locationID = FA.locationID
    JOIN LocationDetails LD ON FA.postalCode = LD.postalCode
    JOIN Plays ply ON ply.sessionNum = S.sessionNum
    JOIN Team T1 ON ply.teamName1 = T1.teamName
    JOIN Team T2 ON ply.teamName2 = T2.teamName
    JOIN Person P1 ON T1.headCoachID = P1.personID
    JOIN Person P2 ON T2.headCoachID = P2.personID
    WHERE S.sessionStartDateTime BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    ORDER BY S.sessionStartDateTime;

    -- Continue handler for session cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open session cursor
    OPEN session_cursor;

    -- Loop through each session
    session_loop: LOOP
        FETCH session_cursor INTO sessionNum, sessionType, sessionStartDateTime, 
        locationName, locationAddress, locationCity, locationProvince, locationPostalCode, 
        teamName1, teamName2, 
        headCoach1FirstName, headCoach1LastName, headCoach1Email, 
        headCoach2FirstName, headCoach2LastName, headCoach2Email;

        IF done THEN 
            LEAVE session_loop; 
        END IF;

        -- Declare a block for the club members' cursor
        BEGIN
            -- Declare a separate done variable for member cursor
            DECLARE member_done INT DEFAULT 0;

            -- Cursor to select club members associated with the teams
            DECLARE member_cursor CURSOR FOR 
            SELECT 
                CM.clubMembershipID, P.firstName, P.lastName, P.emailAddress, 
                AO.role, AO.teamName
            FROM Apart_Of AO
            JOIN ClubMember CM ON AO.personID = CM.personID
            JOIN Person P ON CM.personID = P.personID
            WHERE AO.teamName IN (teamName1, teamName2);

            -- Handler for the member cursor
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET member_done = 1;

            -- Open member cursor
            OPEN member_cursor;

            -- Loop through each member
            member_loop: LOOP
                FETCH member_cursor INTO clubMembershipID, clubMemberFirstName, 
                clubMemberLastName, clubMemberEmail, role, memberTeamName;

                IF member_done THEN 
                    LEAVE member_loop; 
                END IF;

                -- Construct email subject
                SET emailSubject = CONCAT(
                    teamName1, ' vs ', teamName2, 
                    ' on ', DATE_FORMAT(sessionStartDateTime, '%d-%b-%Y %l:%i %p'), 
                    ' ', sessionType, ' session'
                );

                -- Construct email body based on member's team
                IF memberTeamName = teamName1 THEN
                    SET emailBody = CONCAT(
                        'Dear ', clubMemberFirstName, ' ', clubMemberLastName, ',\n\n',
                        'You are scheduled for a ', sessionType, ' session on ',
                        DATE_FORMAT(sessionStartDateTime, '%W, %M %d, %Y'), 
                        ' at ', DATE_FORMAT(sessionStartDateTime, '%l:%i %p'), '.\n\n',
                        'Location: ', locationAddress, ', ', locationCity, ', ', locationProvince, ', ', locationPostalCode, '\n\n',
                        'Your role: ', role, '\n',
                        'Head Coach: ', headCoach1FirstName, ' ', headCoach1LastName, 
                        ' (Email: ', headCoach1Email, ')\n\n',
                        'Best regards,\n',
                        'Your Team Management'
                    );
                ELSE
                    SET emailBody = CONCAT(
                        'Dear ', clubMemberFirstName, ' ', clubMemberLastName, ',\n\n',
                        'You are scheduled for a ', sessionType, ' session on ',
                        DATE_FORMAT(sessionStartDateTime, '%W, %M %d, %Y'), 
                        ' at ', DATE_FORMAT(sessionStartDateTime, '%l:%i %p'), '.\n\n',
                        'Location: ', locationAddress, ', ', locationCity, ', ', locationProvince, ', ', locationPostalCode, '\n\n',
                        'Your role: ', role, '\n',
                        'Head Coach: ', headCoach2FirstName, ' ', headCoach2LastName, 
                        ' (Email: ', headCoach2Email, ')\n\n',
                        'Best regards,\n',
                        'Your Team Management'
                    );
                END IF;

                -- Set receiver (club member email)
                SET receiver = clubMemberEmail;

                -- Log email in EmailLog table
                INSERT INTO EmailLog (sendDate, emailSubject, emailBody, sender, receiver) 
                VALUES (NOW(), emailSubject, emailBody, locationName, receiver);

            END LOOP;

            -- Close member cursor
            CLOSE member_cursor;
        END;

        -- Reset `done` for next iteration
        SET done = 0;
    END LOOP;

    -- Close session cursor
    CLOSE session_cursor;
END;

CREATE EVENT WeeklySessionEmailEvent
ON SCHEDULE EVERY 1 WEEK STARTS '2023-10-22 00:00:00'
DO 
BEGIN
    CALL SendWeeklySessionEmails();
END;
