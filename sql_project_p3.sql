SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM members;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;

-- Project Task and Query Implementations

-- T1. Create a New Book Record : "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.'
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- T2. Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- T3. Delete a Record from the Issued Status Table : Delete the record with issued_id = 'IS121' from the issued_status table
SELECT * FROM issued_status 
WHERE issued_id = 'IS121'; 
DELETE FROM issued_status 
WHERE issued_id = 'IS121'; 

-- T4. Retrieve All Books Issued by a Specific Employee: Select all books issued by the employee with emp_id = 'E101' 

SELECT * FROM issued_status 
WHERE issued_emp_id = 'E101'; 

-- T5: List Members Who Have Issued More Than One Book: Use GROUP BY to find members who have issued more than one book 
SELECT issued_emp_id 
--COUNT(issued_id) as total_book_issued 
FROM issued_status 
GROUP BY 1 
HAVING COUNT(issued_id) > 1; 

--CTAS -- 
-- T6. Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt 
CREATE TABLE book_cnt 
AS 
SELECT 
		b.isbn, 
		b.book_title, 
		COUNT(ist.issued_id) AS no_issued 
		FROM books AS b 
		JOIN issued_status AS ist 
		ON ist.issued_book_isbn = b.isbn 
		GROUP BY 1,2; 
	
-- T7. Retrieve All Books in a Specific Category 

SELECT * FROM books 
WHERE category = 'Classic'; 

-- T8. Find Total Rental Income by Category 

SELECT b.category, 
SUM(b.rental_price) AS total_rental_inc, 
COUNT(*) 
FROM books AS b 
JOIN issued_status AS ist 
ON ist.issued_book_isbn = b.isbn 
GROUP BY 1; 

--T9. List Members Who Registered in the Last 180 Days 

SELECT * FROM members 
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days'; 

INSERT INTO members(member_id, member_name, member_address, reg_date) 
VALUES ('C120', 'Luis', '867 Huda St', '2026-03-10'), 
('C121', 'Jane', '213 Main St', '2026-05-01'); 

--T10. List Employees with Their Branch Manager's Name and their branch details 

SELECT 
		e1.*, 
		b.manager_id, 
		e2.emp_name AS manager 
		FROM employees AS e1 
		JOIN branch b 
		ON b.branch_id = e1.branch_id 
		JOIN employees AS e2 ON b.manager_id = e2.emp_id; 
		
--T11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD 

CREATE TABLE books_price_greater_than_seven 
AS 
SELECT * FROM books 
WHERE rental_price > 7; 
SELECT * FROM books_price_greater_than_seven; 

--T12. Retrieve the List of Books Not Yet Returned 

SELECT 
		DISTINCT ist.issued_book_name 
		FROM issued_status AS ist 
		LEFT JOIN return_status AS rst 
		ON ist.issued_id = rst.issued_id 
		WHERE rst.return_id IS NULL; 
		
--T13. Identify Members with Overdue Books 
/*Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.*/ 

SELECT 
		ist.issued_member_id, 
		m.member_name, 
		b.book_title, 
		ist.issued_date, 
		rst.return_date, 
		(CURRENT_DATE - ist.issued_date) AS overdue_days 
FROM issued_status AS ist 
JOIN members AS m 
	ON ist.issued_member_id = m.member_id 
JOIN books AS b 
	ON b.isbn = ist.issued_book_isbn 
LEFT JOIN return_status rst 
	ON ist.issued_id = rst.issued_id 
WHERE 
	return_date IS NULL 
	AND 
	(CURRENT_DATE - ist.issued_date) > 30 
ORDER BY 1; 
		
--T14. Update Book Status on Return 
/*Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/

WITH returned_books
AS
(SELECT
ist.issued_book_isbn
FROM issued_status ist
JOIN return_status rst
ON ist.issued_id = rst.issued_id)

UPDATE books
SET status = 'yes'
WHERE isbn IN(
			SELECT issued_book_isbn
			FROM returned_books
			)

--T15: Branch Performance Report
/* Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, and the total revenue generated from book rentals*/

CREATE TABLE branch_reports 
AS 
SELECT 
		b.branch_id, 
		b.manager_id, 
		COUNT(ist.issued_id) AS number_book_issued, 
		COUNT(rst.return_id) AS number_of_book_returned, 
		SUM(bk.rental_price) AS total_revenue 
FROM issued_status AS ist 
JOIN employees AS e 	
ON e.emp_id = ist.issued_emp_id 
JOIN branch AS b 
ON e.branch_id = b.branch_id 	
LEFT JOIN return_status AS rst 
ON rst.issued_id = ist.issued_id 
JOIN books AS bk 
ON ist.issued_book_isbn = bk.isbn 
GROUP BY 1, 2;

--T16. CTAS: Create a Table of Active Members
/*Create a new table active_members containing members who have issued at least one book in the last 2 months.*/

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN
				(
				SELECT DISTINCT issued_member_id FROM issued_status
				WHERE issued_date >= CURRENT_DATE - INTERVAL '2 year'
				);
				
SELECT * FROM active_members;

--T17. Find Employees with the Most Book Issues Processed
/* Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch
*/

SELECT 
		e.emp_name,
		b.branch_id,
		COUNT(ist.issued_id) AS no_book_issued
FROM issued_status AS ist
JOIN employees AS e 
ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
ON e.branch_id = b.branch_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 3;

--T18. Write a query to identify members who have issued books with the book_quality marked as 'Damaged' at least once in the return_status table.
/* Display the member name, book title, and the number of times they've issued damaged books */

WITH damaged_books 
AS
(SELECT 
		ist.issued_member_id,
		ist.issued_book_name,
		rst.return_id,
		rst.book_quality
		FROM issued_status as ist
		JOIN return_status as rst
		ON ist.issued_id = rst.issued_id
		WHERE rst.book_quality = 'Damaged'
		)

SELECT m.member_name,
		db.issued_book_name,
		COUNT(db.return_id) as damage_cnt

FROM damaged_books as db
JOIN members as m
ON db.issued_member_id = m.member_id

GROUP BY 1,2
HAVING COUNT(db.return_id) >= 1;

--T19. Stored Procedure
/* Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE issue_book(
	p_book_id VARCHAR(20))

LANGUAGE plpgsql

AS $$
	DECLARE v_status VARCHAR(10);

BEGIN
	--Checking Current Status
	SELECT status
	INTO v_status
	FROM books 
	WHERE isbn = p_book_id;

	-- If available
	IF v_status = 'yes' THEN

		UPDATE books
		SET status = 'no'
		WHERE isbn = p_book_id;

		RAISE NOTICE 'Book issued successfully';

	-- If unavailable
	ELSE
	
		RAISE NOTICE 'Book is currently unavailable';

	END IF;
	
END;
$$;

-- Testing The function
SELECT * FROM books;
SELECT * FROM issued_status;
CALL issue_book('978-0-553-29698-2');
CALL issue_book('978-0-375-41398-8');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

--T20. Create Table As Select (CTAS)**
/* Objective: Create a CTAS query to identify overdue books and calculate fines.
Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include:
The number of overdue books.
The total fines, with each day's fine calculated at $0.50.
The number of books issued by each member.
The resulting table should show:
Member ID
Number of overdue books
Total fines
*/

CREATE TABLE overdue_fine AS
	SELECT
	ist.issued_member_id AS member_id,
	COUNT(*) AS no_of_overdue_books,
	SUM(((CURRENT_DATE - ist.issued_date) - 30) * 0.50) AS total_fine
	
FROM issued_status AS ist
LEFT JOIN return_status AS rst
    ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL
AND (CURRENT_DATE - ist.issued_date) > 30
GROUP BY 1;

SELECT * FROM overdue_fine;

-- END OF PROJECT --
