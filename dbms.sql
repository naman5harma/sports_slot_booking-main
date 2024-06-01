CREATE DATABASE sports_booking;
use sports_booking;
CREATE TABLE sports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,  -- Hashed in production
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15),
    roll_number VARCHAR(50) UNIQUE
);
CREATE TABLE slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sport_id INT,
    slot_type ENUM('TueThuSat', 'MonWedFri') NOT NULL,
    time TIME NOT NULL,
    FOREIGN KEY (sport_id) REFERENCES sports(id)
);
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    slot_id INT,
    booking_time DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (slot_id) REFERENCES slots(id)
);
INSERT INTO sports (name) VALUES ('Badminton'), ('Basketball'), ('Yoga'), ('Gym'), ('Dance'), ('Table Tennis'), ('Martial Arts'), ('Chess');

INSERT INTO users (username, password, email, phone_number, roll_number) VALUES
('ishaan', 'password123', 'ish@example.com', '1234567890', 'RN1001');

INSERT INTO users (username, password, email, phone_number, roll_number) VALUES
('naman', 'password123', 'nam@example.com', '1234567890', 'RN1002');

INSERT INTO users (username, password, email, phone_number, roll_number) VALUES
('rishik', 'password123', 'nam@example.com', '1234567890', 'RN1003');

ALTER TABLE slots
ADD COLUMN end_time TIME NOT NULL AFTER time;
ALTER TABLE slots RENAME COLUMN time TO start_time; 

INSERT INTO slots (sport_id, slot_type, start_time, end_time) VALUES
(1, 'TueThuSat', '08:00:00', '09:00:00'),
(2, 'MonWedFri', '10:00:00', '11:00:00');

INSERT INTO slots (sport_id, slot_type, start_time, end_time) VALUES
(3, 'TueThuSat', '07:00:00', '09:00:00'),
(3, 'MonWedFri', '19:00:00', '11:00:00');

ALTER TABLE slots ADD COLUMN capacity INT NOT NULL;

select * from users;

DELIMITER //

CREATE TRIGGER check_slot_capacity BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE slot_capacity INT;
    DECLARE current_bookings INT;

    SELECT capacity INTO slot_capacity FROM slots WHERE id = NEW.slot_id;
    SELECT COUNT(*) INTO current_bookings FROM bookings WHERE slot_id = NEW.slot_id;

    IF current_bookings >= slot_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slot capacity exceeded';
    END IF;
END //

DELIMITER ;


UPDATE slots SET capacity = 12 WHERE id = 1;
UPDATE slots SET capacity = 15 WHERE id = 2;
UPDATE slots SET capacity = 10 WHERE id = 3;
UPDATE slots SET capacity = 20 WHERE id = 4;


desc slots;

SELECT id, start_time, end_time FROM slots WHERE sporgbthryhryhjynqmannamana snarmnaaaaaaaaat_id = 1;
select * from slots;
select * from bookings;
select * from users;
select * from sports;

create table admins (id INT AUTO_INCREMENT PRIMARY KEY, admin_username VARCHAR(255) NOT NULL, admin_password VARCHAR(255) NOT NULL);

DELIMITER //

CREATE PROCEDURE AddAdmin(IN new_username VARCHAR(255), IN new_password VARCHAR(255))
BEGIN
    -- Inserting a new admin into the admins table
    INSERT INTO admins (admin_username, admin_password) VALUES (new_username, new_password);
END //

DELIMITER ;

CALL AddAdmin('admin1', 'admin1');
select * from admins;

select * from slots;

DELIMITER //

CREATE PROCEDURE GetBookings()
BEGIN
    SELECT * FROM bookings;
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE GetSlots()
BEGIN
    SELECT * FROM slots;
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE GetUsers()
BEGIN
    SELECT * FROM users;
END //

DELIMITER ;

select * from admins;


DELIMITER //

CREATE PROCEDURE CheckAdminCredentials(IN input_username VARCHAR(255), IN input_password VARCHAR(255), OUT is_valid TINYINT)
BEGIN
    SELECT EXISTS(SELECT 1 FROM admins WHERE admin_username = input_username AND admin_password = input_password) INTO is_valid;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE GetFormattedBookings()
BEGIN
    SELECT 
        u.name AS UserName, 
        b.slot_id AS SlotID, 
        DATE_FORMAT(b.booking_time, '%Y-%m-%d %H:%i:%s') AS BookingTime
    FROM 
        bookings b
    JOIN 
        users u ON b.user_id = u.id
    JOIN 
        slots s ON b.slot_id = s.id;
END //

DELIMITER ;

drop PROCEDURE GetFormattedBookings;

DELIMITER //

CREATE PROCEDURE GetFormattedBookings()
BEGIN
    SELECT 
        users.username AS UserName,  -- Adjust 'name' if the column name is different
        bookings.slot_id AS SlotID, 
        DATE_FORMAT(bookings.booking_time, '%Y-%m-%d %H:%i:%s') AS BookingTime
    FROM 
        bookings
    JOIN 
        users ON bookings.user_id = users.id;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE GetFormattedSlots()
BEGIN
    SELECT 
        slots.id AS SlotID, 
        sports.name AS SportName,
        slots.slot_type AS SlotType,
        TIME_FORMAT(slots.start_time, '%H:%i') AS StartTime,
        TIME_FORMAT(slots.end_time, '%H:%i') AS EndTime,
        slots.capacity AS Capacity
    FROM 
        slots
    JOIN 
        sports ON slots.sport_id = sports.id;
END //

DELIMITER ;

select * from users;



DELIMITER //

CREATE TRIGGER before_booking_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    -- Check if the user already has a booking for the same sport
    DECLARE already_booked BOOLEAN DEFAULT FALSE;
    SELECT EXISTS (
        SELECT 1
        FROM bookings AS b
        JOIN slots AS s ON b.slot_id = s.id
        WHERE b.user_id = NEW.user_id AND s.sport_id = (SELECT sport_id FROM slots WHERE id = NEW.slot_id)
    ) INTO already_booked;

    -- If the user already has a booking for the sport, signal an error
    IF already_booked THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A user can only book one slot for a sport.';
    END IF;
END //

DELIMITER ;

DELIMITER //



CREATE TRIGGER before_booking_insert_time
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE clash_found BOOLEAN DEFAULT FALSE;

    SELECT EXISTS (
        SELECT 1
        FROM bookings AS b
        JOIN slots AS existing_slot ON b.slot_id = existing_slot.id
        JOIN slots AS new_slot ON NEW.slot_id = new_slot.id
        WHERE 
            b.user_id = NEW.user_id AND
            (
                (new_slot.start_time BETWEEN existing_slot.start_time AND existing_slot.end_time) OR
                (new_slot.end_time BETWEEN existing_slot.start_time AND existing_slot.end_time) OR
                (existing_slot.start_time BETWEEN new_slot.start_time AND new_slot.end_time) OR
                (existing_slot.end_time BETWEEN new_slot.start_time AND new_slot.end_time)
            )
    ) INTO clash_found;

    IF clash_found THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The booking time clashes with an existing booking.';
    END IF;
END //

DELIMITER ;


drop TRIGGER before_booking_insert_time;

DELIMITER //

CREATE TRIGGER before_booking_insert_time
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE clash_found BOOLEAN DEFAULT FALSE;

    SELECT EXISTS (
        SELECT 1
        FROM bookings AS b
        JOIN slots AS existing_slot ON b.slot_id = existing_slot.id
        JOIN slots AS new_slot ON NEW.slot_id = new_slot.id
        WHERE 
            b.user_id = NEW.user_id AND
            existing_slot.slot_type = new_slot.slot_type AND
            (
                (new_slot.start_time BETWEEN existing_slot.start_time AND existing_slot.end_time) OR
                (existing_slot.start_time BETWEEN new_slot.start_time AND new_slot.end_time)
            )
    ) INTO clash_found;

    IF clash_found THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The booking time clashes with an existing booking.';
    END IF;
END //

DELIMITER ;

CREATE PROCEDURE GetSlotsForSport(IN input_sport_id INT)
BEGIN
    SELECT 
        id AS SlotID, 
        TIME_FORMAT(start_time, '%H:%i') AS StartTime, 
        TIME_FORMAT(end_time, '%H:%i') AS EndTime,
        slot_type AS Days
    FROM slots 
    WHERE sport_id = input_sport_id;
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE BookSlot(IN input_user_id INT, IN input_slot_id INT)
BEGIN
    INSERT INTO bookings (user_id, slot_id, booking_time) VALUES (input_user_id, input_slot_id, NOW());
END //

DELIMITER ;