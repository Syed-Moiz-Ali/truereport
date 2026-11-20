package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Option-set values become key-addressed like statuses.
 *
 * <p>Adds a nullable {@code label_key} to {@code platform_option_values} and
 * backfills every row with the deterministic convention
 * {@code option.<lowerCamel(setCode)>.<lowerCamel(valueCode)>}. Existing
 * non-null keys are never rewritten and the backfill is safe to run twice.</p>
 */
public class V128__Option_value_label_keys extends BaseJavaMigration {

    private static final String COLUMN = "label_key";
    private static final String TABLE = "platform_option_values";

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        addColumnIfMissing(connection);
        backfill(connection);
    }

    /**
     * Idempotent backfill: only rows with a null/blank key are updated, and the
     * update repeats the same predicate so a concurrent writer cannot have its
     * explicit key overwritten.
     */
    public static void backfill(Connection connection) throws SQLException {
        List<ValueRow> rows = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery("""
                     SELECT v.id, s.code AS set_code, v.code AS value_code
                     FROM platform_option_values v
                     JOIN platform_option_sets s ON s.id = v.option_set_id
                     WHERE v.label_key IS NULL OR v.label_key = ''
                     ORDER BY v.id
                     """)) {
            while (result.next()) {
                rows.add(new ValueRow(result.getString("id"), result.getString("set_code"),
                        result.getString("value_code")));
            }
        }
        if (rows.isEmpty()) {
            return;
        }
        try (PreparedStatement update = connection.prepareStatement("""
                UPDATE platform_option_values SET label_key = ?
                WHERE id = ? AND (label_key IS NULL OR label_key = '')
                """)) {
            for (ValueRow row : rows) {
                update.setString(1, generateKey(row.setCode(), row.valueCode()));
                update.setString(2, row.id());
                update.addBatch();
            }
            update.executeBatch();
        }
    }

    static String generateKey(String optionSetCode, String valueCode) {
        return "option." + lowerCamel(optionSetCode) + "." + lowerCamel(valueCode);
    }

    private static void addColumnIfMissing(Connection connection) throws SQLException {
        if (columnExists(connection)) {
            return;
        }
        try (Statement statement = connection.createStatement()) {
            statement.execute("ALTER TABLE " + TABLE + " ADD COLUMN " + COLUMN
                    + " VARCHAR(120) NULL");
        } catch (SQLException exception) {
            // Re-check so a parallel/previous partial run is not treated as a failure.
            if (!columnExists(connection)) {
                throw exception;
            }
        }
    }

    private static boolean columnExists(Connection connection) throws SQLException {
        DatabaseMetaData metadata = connection.getMetaData();
        for (String table : List.of(TABLE, TABLE.toUpperCase())) {
            for (String column : List.of(COLUMN, COLUMN.toUpperCase())) {
                try (ResultSet result = metadata.getColumns(
                        connection.getCatalog(), null, table, column)) {
                    if (result.next()) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static String lowerCamel(String code) {
        if (code == null) {
            return "value";
        }
        StringBuilder result = new StringBuilder();
        boolean upperNext = false;
        for (int index = 0; index < code.length(); index++) {
            char character = code.charAt(index);
            boolean alphaNumeric = (character >= 'a' && character <= 'z')
                    || (character >= 'A' && character <= 'Z')
                    || (character >= '0' && character <= '9');
            if (!alphaNumeric) {
                if (result.length() > 0) {
                    upperNext = true;
                }
                continue;
            }
            if (result.length() == 0) {
                result.append(Character.toLowerCase(character));
            } else if (upperNext) {
                result.append(Character.toUpperCase(character));
                upperNext = false;
            } else {
                result.append(Character.toLowerCase(character));
            }
        }
        if (result.length() == 0) {
            return "value";
        }
        if (!Character.isLetter(result.charAt(0))) {
            result.insert(0, 'v');
        }
        return result.toString();
    }

    private record ValueRow(String id, String setCode, String valueCode) {
    }
}
