/*

Cleaning SQL Data

1. Standardize date format
2. Populate property address data
3. Split address into individual columns
4. Change "Y" and "N" to "Yes" and "No" in "Sold as Vacant" field
5. Remove duplicates
6. Delete unused columns

*/

SELECT *
FROM PortfolioProject..NashvilleHousing

-- 1. Standardize Date Format

-- Remove trailing zeros for time, leaving only yyyy-mm-dd

SELECT 
	SaleDate, 
	CONVERT(Date,SaleDate)
FROM PortfolioProject..NashvilleHousing

-- Note: UPDATE will not work as we are not changing the data but rather the data structure
-- Ref: https://www.geeksforgeeks.org/difference-between-alter-and-update-command-in-sql/

-- Add column
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

-- Add data to column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

-- Drop old column
ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate

-- Test
SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing

-- 2. Populate Property Address Data

-- Replace null values

SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null

SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER by ParcelID

-- ParcelIDs that are the same also have the same property address
-- Do SELF JOIN: Join table to itself where ParcelID the same but uniqueID is different

SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	--This keeps it from joining to itself
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Test
-- Should return no results

SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	--This keeps it from joining to itself
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
-- Success!

-- 3. Split address into Individual Columns

-- Currently shows City/State after street address
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City
FROM PortfolioProject..NashvilleHousing

-- Add column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

-- Add data to column
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

-- Add column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

-- Add data to column
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

-- Test
SELECT PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing
-- Success!

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing
WHERE OwnerAddress is not null


-- Add column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

-- Add data to column
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

-- Add column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

-- Add data to column
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

-- Add column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

-- Add data to column
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Test
SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing
Where OwnerAddress is not null
-- Success!

-- 4. Change Y and N to Yes and No in "Sold as Vacant" field

-- Bring up distinct values for field
-- Should just be 2 values but there are 4

SELECT 
	DISTINCT(SoldAsVacant), 
	COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
Group by SoldAsVacant
ORDER BY 2 desc

-- Change values using CASE statement

SELECT 
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject..NashvilleHousing

-- Update using above query

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

-- Test
SELECT 
	DISTINCT(SoldAsVacant), 
	COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
Group by SoldAsVacant
ORDER BY 2 desc
-- Success! Only 2 values

-- 5. Remove duplicates

-- Select duplicate rows that only have different UniqueIDs

SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDateConverted,
		LegalReference
	ORDER BY
		UniqueID)
	row_num			
FROM PortfolioProject..NashvilleHousing
Order by ParcelID desc
-- These 104 entries are dupilicates and need to be deleted

-- Use CTE
With RowNumeCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDateConverted,
		LegalReference
	ORDER BY
		UniqueID)
	row_num			
FROM PortfolioProject..NashvilleHousing
)
-- Delete entries
DELETE
FROM RowNumeCTE
WHERE row_num > 1
-- Sucess! 104 rows deleted

-- Test (result should be empty)
With RowNumeCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDateConverted,
		LegalReference
	ORDER BY
		UniqueID)
	row_num			
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumeCTE
WHERE row_num > 1
-- Success! Empty!

-- 6. Delete unused columns

-- Delete: TaxDistrict, OwnerAddress, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN TaxDistrict, OwnerAddress, PropertyAddress 

-- Test
SELECT *
FROM PortfolioProject..NashvilleHousing
-- Success!