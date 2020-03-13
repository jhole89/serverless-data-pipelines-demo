CREATE OR REPLACE VIEW reporting_{} AS
    SELECT
          *
    FROM "{}"
    WHERE SOURCE == 'bestbuy'
