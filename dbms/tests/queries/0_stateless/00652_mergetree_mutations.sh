#!/usr/bin/env bash

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $CURDIR/../shell_config.sh

${CLICKHOUSE_CLIENT} --query="DROP TABLE IF EXISTS test.mutations"

${CLICKHOUSE_CLIENT} --query="CREATE TABLE test.mutations(d Date, x UInt32, s String, a UInt32 ALIAS x + 1) ENGINE MergeTree(d, intDiv(x, 10), 8192)"

# Test a mutation on empty table
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE x = 1"

# Insert some data
${CLICKHOUSE_CLIENT} --query="INSERT INTO test.mutations(d, x, s) VALUES \
    ('2000-01-01', 1, 'a')"
${CLICKHOUSE_CLIENT} --query="INSERT INTO test.mutations(d, x, s) VALUES \
    ('2000-01-01', 2, 'b'), ('2000-01-01', 3, 'c'), ('2000-01-01', 4, 'd') \
    ('2000-02-01', 2, 'b'), ('2000-02-01', 3, 'c'), ('2000-02-01', 4, 'd')"

# Try some malformed queries that should fail validation.
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE nonexistent = 0" 2>/dev/null || echo "Query should fail 1"
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE d = '11'" 2>/dev/null || echo "Query should fail 2"
# TODO: Queries involving alias columns are not supported yet and should fail on submission.
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE a = 0" 2>/dev/null || echo "Query involving aliases should fail on submission"

# Delete some values
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE x % 2 = 1"
${CLICKHOUSE_CLIENT} --query="ALTER TABLE test.mutations DELETE WHERE s = 'd'"

# Insert more data
${CLICKHOUSE_CLIENT} --query="INSERT INTO test.mutations(d, x, s) VALUES \
    ('2000-01-01', 5, 'e'), ('2000-02-01', 5, 'e')"

# Wait until all mutations are done.
for i in {1..100}
do
    sleep 0.1
    if [[ $(${CLICKHOUSE_CLIENT} --query="SELECT sum(is_done) FROM system.mutations WHERE table='mutations'") -eq 3 ]]; then
        break
    fi

    if [[ $i -eq 100 ]]; then
       echo "Timed out while waiting for mutations to execute!"
    fi
done

# Check that the table contains only the data that should not be deleted.
${CLICKHOUSE_CLIENT} --query="SELECT * FROM test.mutations ORDER BY d, x"
# Check the contents of the system.mutations table.
${CLICKHOUSE_CLIENT} --query="SELECT mutation_id, command, block_numbers.partition_id, block_numbers.number, parts_to_do, is_done \
    FROM system.mutations WHERE table = 'mutations' ORDER BY mutation_id"

${CLICKHOUSE_CLIENT} --query="DROP TABLE test.mutations"
