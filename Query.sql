-- Retrieve location details along with general manager name and count of club members.
SELECT 
    L.locationName,
    LD.address,
    LD.city,
    LD.province,
    LD.postalCode,
    L.phoneNumber,
    L.webAddress,
    L.type,
    L.capacity,
    -- Use COALESCE to display 'No General Manager' if no match is found.
    COALESCE(CONCAT(P.firstName, ' ', P.lastName), 'No General Manager') AS generalManagerName,
    COUNT(DISTINCT A.clubMemberID) AS numOfClubMembers
FROM Location L
LEFT JOIN Found_At FA 
    ON L.locationID = FA.locationID
LEFT JOIN LocationDetails LD 
    ON FA.postalCode = LD.postalCode
LEFT JOIN Manages M 
    ON L.locationID = M.locationID 
    AND M.endDate IS NULL
LEFT JOIN Personnel Per 
    ON M.personID = Per.personID 
    AND Per.role = 'Administrator'
LEFT JOIN Person P 
    ON Per.personID = P.personID
LEFT JOIN Assignment A 
    ON L.locationID = A.LocationID 
    AND M.endDate IS NULL
GROUP BY 
    L.locationID,
    L.locationName,
    LD.address,
    LD.city,
    LD.province,
    LD.postalCode,
    L.phoneNumber,
    L.webAddress,
    L.type,
    L.capacity,
    P.firstName,
    P.lastName
ORDER BY 
    LD.province,
    LD.city;

-- Retrieve secondary family member details for a given primary family member (familyMemberID = 2).
SELECT DISTINCT 
    SF.firstName AS secondaryFirstName, 
    SF.lastName AS secondaryLastName, 
    SF.telephoneNumber AS secondaryPhoneNumber, 
    CM.clubMembershipID, 
    P.firstName AS clubMemberFirstName, 
    P.lastName AS clubMemberLastName, 
    P.dateOfBirth, 
    P.SSN, 
    P.medicareCardNumber, 
    P.telephoneNumber AS clubMemberPhoneNumber, 
    LD.address, 
    LD.city, 
    LD.province, 
    LD.postalCode, 
    A.secondaryRelation AS secondaryRelation
FROM Assignment A
LEFT JOIN SecondaryFamilyMember SF 
    ON A.familyMemberID = SF.primaryFamilyMemberID 
    AND A.secondaryID = SF.secondaryFamilyMemberID
LEFT JOIN ClubMember CM 
    ON A.clubMemberID = CM.personID
LEFT JOIN Person P 
    ON CM.personID = P.personID
LEFT JOIN Lives_At LA 
    ON P.personID = LA.personID
LEFT JOIN LocationDetails LD 
    ON LA.postalCode = LD.postalCode
WHERE A.familyMemberID = 2;

-- Retrieve detailed session information for sessions on '2024-08-03' at location with ID 7.
SELECT 
    p.teamName1 AS 'Team Name 1',
    hc1.firstName AS 'Head Coach 1 First Name',
    hc1.lastName AS 'Head Coach 1 Last Name',
    p.teamName2 AS 'Team Name 2',
    hc2.firstName AS 'Head Coach 2 First Name',
    hc2.lastName AS 'Head Coach 2 Last Name',
    s.sessionStartDateTime AS 'Session Start Time',
    CONCAT(ld.address, ', ', ld.city, ', ', ld.province, ', ', ld.postalCode) AS 'Session Address',
    s.sessionType AS 'Session Type',
    s.team1Score AS 'Team 1 Score',
    s.team2Score AS 'Team 2 Score',
    per.firstName AS 'Player First Name',
    per.lastName AS 'Player Last Name',
    ao.role AS 'Player Role'
FROM Sessions s
JOIN Plays p ON s.sessionNum = p.sessionNum
LEFT JOIN Found_At fa ON s.locationID = fa.locationID
LEFT JOIN LocationDetails ld ON fa.postalCode = ld.postalCode
LEFT JOIN Team t1 ON p.teamName1 = t1.teamName
LEFT JOIN Personnel pc1 ON t1.headCoachID = pc1.personID
LEFT JOIN Person hc1 ON pc1.personID = hc1.personID
LEFT JOIN Team t2 ON p.teamName2 = t2.teamName
LEFT JOIN Personnel pc2 ON t2.headCoachID = pc2.personID
LEFT JOIN Person hc2 ON pc2.personID = hc2.personID
LEFT JOIN Apart_Of ao ON t1.teamName = ao.teamName OR t2.teamName = ao.teamName
LEFT JOIN ClubMember cm ON ao.personID = cm.personID
LEFT JOIN Person per ON cm.personID = per.personID
WHERE DATE(s.sessionStartDateTime) = '2024-08-03'
  AND s.locationID = 7
ORDER BY s.sessionStartDateTime ASC;

-- Retrieve club members aged between 4 and 10 years who have been assigned for at most 2 years 
-- and have assignments in at least 4 distinct locations.
SELECT DISTINCT 
    cm.clubMembershipID, 
    p.firstName, 
    p.lastName
FROM ClubMember cm
JOIN Person p ON cm.personID = p.personID
JOIN Assignment a ON cm.personID = a.clubMemberID
WHERE TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND DATEDIFF(CURDATE(), (
      SELECT MIN(a1.startDate)
      FROM Assignment a1
      WHERE a1.clubMemberID = cm.personID
  )) <= 2 * 365
  AND cm.personID IN (
      SELECT a2.clubMemberID
      FROM Assignment a2
      GROUP BY a2.clubMemberID
      HAVING COUNT(DISTINCT a2.locationID) >= 4
  )
ORDER BY cm.clubMembershipID ASC;

-- Retrieve statistics on training and game sessions per location, including player counts.
SELECT 
    l.locationName, 
    COUNT(CASE WHEN s.sessionType = 'Training' THEN 1 END) AS totalTrainingSessions, 
    SUM(CASE WHEN s.sessionType = 'Training' THEN p.playerCount ELSE 0 END) AS totalPlayersInTrainingSessions, 
    COUNT(CASE WHEN s.sessionType = 'Game' THEN 1 END) AS totalGameSessions, 
    SUM(CASE WHEN s.sessionType = 'Game' THEN p.playerCount ELSE 0 END) AS totalPlayersInGameSessions
FROM Sessions s
LEFT JOIN Location l ON l.locationID = s.locationID
LEFT JOIN (
    SELECT 
        s.locationID, 
        s.sessionNum, 
        (COUNT(a1.personID) + COUNT(a2.personID)) AS playerCount
    FROM Sessions s
    JOIN Plays pl ON s.sessionNum = pl.sessionNum
    JOIN Apart_Of a1 ON pl.teamName1 = a1.teamName
    JOIN Apart_Of a2 ON pl.teamName2 = a2.teamName
    WHERE s.sessionStartDateTime BETWEEN '2024-04-01' AND '2024-08-31'
    GROUP BY s.locationID, s.sessionNum
) p ON s.sessionNum = p.sessionNum
WHERE s.sessionStartDateTime BETWEEN '2024-04-01' AND '2024-08-31'
GROUP BY l.locationName
HAVING COUNT(CASE WHEN s.sessionType = 'Game' THEN 1 END) >= 3
ORDER BY totalGameSessions DESC;

-- Retrieve club members aged between 4 and 10 who have no team assignment.
SELECT 
    cm.clubMembershipID, 
    p.firstName, 
    p.lastName,
    TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) AS age,
    p.telephoneNumber,
    p.emailAddress,
    l.locationName AS currentLocationName
FROM ClubMember cm
JOIN Person p ON cm.personID = p.personID
JOIN Assignment a ON cm.personID = a.clubMemberID
JOIN Location l ON a.locationID = l.locationID
WHERE TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND cm.personID NOT IN (SELECT Apart_Of.personID FROM Apart_Of)
  AND a.endDate IS NULL
ORDER BY l.locationName ASC, cm.clubMembershipID ASC;

-- Retrieve club members aged between 4 and 10 who have only one distinct role ('Goalkeeper').
SELECT 
    cm.clubMembershipID, 
    p.firstName, 
    p.lastName,
    TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) AS age,
    p.telephoneNumber,
    p.emailAddress,
    l.locationName AS currentLocationName
FROM Person p
JOIN ClubMember cm ON p.personID = cm.personID
JOIN Assignment a ON cm.personID = a.clubMemberID
JOIN Location l ON a.locationID = l.locationID
WHERE TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND a.endDate IS NULL
  AND cm.personID IN (
      SELECT personID 
      FROM Apart_Of
      GROUP BY personID
      HAVING COUNT(DISTINCT role) = 1 
         AND MIN(role) = 'Goalkeeper'
  )
ORDER BY l.locationName ASC, cm.clubMembershipID ASC;

-- Retrieve club members aged between 4 and 10 who participated in 'Game' sessions 
-- and have exactly 4 distinct roles.
SELECT DISTINCT 
    cm.clubMembershipID, 
    p.firstName, 
    p.lastName,
    TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) AS age,
    p.telephoneNumber,
    p.emailAddress,
    l.locationName AS currentLocationName
FROM Person p
JOIN ClubMember cm ON p.personID = cm.personID
JOIN Assignment a ON cm.personID = a.clubMemberID
JOIN Location l ON a.locationID = l.locationID
JOIN Apart_Of ao ON cm.personID = ao.personID
JOIN Plays py ON ao.teamName = py.teamName1 OR ao.teamName = py.teamName2
JOIN Sessions s ON py.sessionNum = s.sessionNum
WHERE TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND s.sessionType = 'Game'
  AND cm.personID IN (
      SELECT personID 
      FROM Apart_Of
      GROUP BY personID
      HAVING COUNT(DISTINCT role) = 4
  )
ORDER BY l.locationName ASC, cm.clubMembershipID ASC;

-- Retrieve distinct family members (head coaches) associated with teams at a given location.
SELECT DISTINCT 
    p1.firstName, 
    p1.lastName, 
    p1.telephoneNumber
FROM Person p1
JOIN FamilyMember fm ON p1.personID = fm.personID
JOIN Assignment a1 ON fm.personID = a1.familyMemberID
JOIN ClubMember cm ON a1.clubMemberID = cm.personID
JOIN Person p2 ON cm.personID = p2.personID
JOIN Location l ON a1.locationID = l.locationID
JOIN Formed_At fa ON l.locationID = fa.locationID
JOIN Team t ON fa.teamName = t.teamName
WHERE l.locationID = ?
  AND TIMESTAMPDIFF(YEAR, p2.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND a1.endDate IS NULL
  AND t.headCoachID = p1.personID;

-- Retrieve club members aged between 4 and 10 who participated in 'Game' sessions,
-- where their team won, and they have no record of losing.
SELECT DISTINCT 
    cm.clubMembershipID, 
    p.firstName, 
    p.lastName, 
    TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) AS age, 
    p.telephoneNumber, 
    p.emailAddress, 
    l.locationName
FROM ClubMember cm
JOIN Person p ON cm.personID = p.personID
JOIN Assignment a ON cm.personID = a.clubMemberID
JOIN Location l ON a.locationID = l.locationID
JOIN Apart_Of ap ON cm.personID = ap.personID
JOIN Team t ON ap.teamName = t.teamName
JOIN Plays py ON ap.teamName = py.teamName1 OR ap.teamName = py.teamName2
JOIN Sessions s ON py.sessionNum = s.sessionNum
WHERE TIMESTAMPDIFF(YEAR, p.dateOfBirth, CURDATE()) BETWEEN 4 AND 10
  AND a.endDate IS NULL
  AND s.sessionType = 'Game'
  AND (
      (s.team1Score > s.team2Score AND ap.teamName = py.teamName1) OR
      (s.team2Score > s.team1Score AND ap.teamName = py.teamName2)
  )
  AND NOT EXISTS (
      SELECT 1
      FROM Plays py2
      JOIN Sessions s2 ON py2.sessionNum = s2.sessionNum
      JOIN Apart_Of ap2 ON (ap2.teamName = py2.teamName1 OR ap2.teamName = py2.teamName2)
      WHERE ap2.personID = cm.personID
        AND (
            (s2.team1Score < s2.team2Score AND ap2.teamName = py2.teamName1) OR 
            (s2.team2Score < s2.team1Score AND ap2.teamName = py2.teamName2)
        )
  )
ORDER BY l.locationName ASC, cm.clubMembershipID ASC;

-- Retrieve first and last names along with the tenure of presidents (personnel managing 'Head' locations).
SELECT 
    p.firstName, 
    p.lastName, 
    m.startDate AS presidentStartDate, 
    m.endDate AS presidentEndDate
FROM Person p
JOIN Personnel psnl ON p.personID = psnl.personID
JOIN Manages m ON psnl.personID = m.personID
JOIN Location l ON m.locationID = l.locationID
WHERE l.type = 'Head'
ORDER BY 
    p.firstName ASC, 
    p.lastName ASC, 
    m.startDate ASC;

-- Retrieve volunteer personnel details from both the Operates and Manages tables,
-- excluding those who are also family members. Uses UNION to combine both result sets.
SELECT 
    p.firstName, 
    p.lastName, 
    p.telephoneNumber, 
    p.emailAddress,
    psnl.role, 
    l.locationName
FROM Person p
JOIN Personnel psnl ON p.personID = psnl.personID
JOIN Operates o ON psnl.personID = o.personID
JOIN Location l ON o.locationID = l.locationID
WHERE psnl.mandate = 'Volunteer'
  AND o.endDate IS NULL
  AND psnl.personID NOT IN (SELECT FamilyMember.personID FROM FamilyMember)

UNION

SELECT 
    p.firstName, 
    p.lastName, 
    p.telephoneNumber, 
    p.emailAddress,
    psnl.role, 
    l.locationName
FROM Person p
JOIN Personnel psnl ON p.personID = psnl.personID
JOIN Manages m ON psnl.personID = m.personID
JOIN Location l ON m.locationID = l.locationID
WHERE psnl.mandate = 'Volunteer'
  AND m.endDate IS NULL
  AND psnl.personID NOT IN (SELECT FamilyMember.personID FROM FamilyMember)
ORDER BY 
    locationName ASC, 
    role ASC, 
    firstName ASC, 
    lastName ASC;
