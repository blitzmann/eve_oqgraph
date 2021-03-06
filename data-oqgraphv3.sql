-- Initializes OQGRAPH tables

CREATE TABLE _oqMarket (
  origid INT UNSIGNED NOT NULL,
  destid INT UNSIGNED NOT NULL,
  PRIMARY KEY (origid, destid),
  KEY (destid)
);

CREATE TABLE _oqJumps (
  origid INT UNSIGNED NOT NULL,
  destid INT UNSIGNED NOT NULL,
  PRIMARY KEY (origid, destid),
  KEY (destid)
);

CREATE TABLE oqJumps (
  latch VARCHAR(32) NULL,
  origid BIGINT UNSIGNED NULL,
  destid BIGINT UNSIGNED NULL,
  weight DOUBLE NULL,
  seq BIGINT UNSIGNED NULL,
  linkid BIGINT UNSIGNED NULL,
  KEY (latch, origid, destid) USING HASH,
  KEY (latch, destid, origid) USING HASH
)
ENGINE=OQGRAPH
data_table='_oqJumps' origid='origid' destid='destid';


CREATE TABLE oqMarket (
  latch VARCHAR(32) NULL,
  origid BIGINT UNSIGNED NULL,
  destid BIGINT UNSIGNED NULL,
  weight DOUBLE NULL,
  seq BIGINT UNSIGNED NULL,
  linkid BIGINT UNSIGNED NULL,
  KEY (latch, origid, destid) USING HASH,
  KEY (latch, destid, origid) USING HASH
)
ENGINE=OQGRAPH
data_table='_oqMarket' origid='origid' destid='destid';

-- ----------------------------
-- Market Tree
-- ----------------------------
--
--  The EVE market tree does not have a single parent listed in the database.
--  Instead, the entire market is broken into 15 different trees (Blueprints,
--  Ships, etc being the parent of each tree). This causes problems, becasue
--  when trying to find the path from a type to it's top-most parent, we need to
--  have a known singular ID. When we're working with various trees in 1 query,
--  we won't know what the top-most parent is, and thus it's difficult to find
--  the path (since origid is unknown).
--
--  So we effectively add a node that becomes to root to all 15 trees. This
--  root is ID 1, and we'll call it, creatively enough, the EVE Market, although
--  that is not a name available in the database. It's how we say "Everything
--  that connects to ID 1 is in the market".
--
--  This can also branch out to other trees in the database, by giving them
--  their own ID and just having a generic `graph` table. That's something for a
--  rainy day.
--

--
-- We insert the current market tree into OQGRAPH
-- This ignores the top-most node of the tree (the NULLs)
--

INSERT INTO _oqMarket (origid, destid) SELECT parentGroupID, marketGroupID FROM invMarketGroups WHERE parentGroupID IS NOT NULL;
INSERT INTO _oqMarket (destid, origid) SELECT parentGroupID, marketGroupID FROM invMarketGroups WHERE parentGroupID IS NOT NULL;

--
-- We give the top-level nodes of each tree a parent ID of 1, which effectively
-- connects them all together and gives us a known, singular parent to everything
--

INSERT INTO _oqMarket (destid, origid) SELECT 1, marketGroupID FROM invMarketGroups WHERE parentGroupID IS NULL;
INSERT INTO _oqMarket (origid, destid) SELECT 1, marketGroupID FROM invMarketGroups WHERE parentGroupID IS NULL;


-- ----------------------------
-- Jumps graph
-- ----------------------------

INSERT INTO _oqJumps (origid, destid) SELECT toSolarSystemID, fromSolarSystemID FROM mapSolarSystemJumps;
