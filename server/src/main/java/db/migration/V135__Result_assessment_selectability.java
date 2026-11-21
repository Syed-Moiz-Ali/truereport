package db.migration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Data-only fix for the merged RESULT taxonomy.
 *
 * <p>Only the three assessment outcomes are user-selectable in the item editor.
 * {@code NOT_CHECKED}, {@code NOT_APPLICABLE} and {@code COULD_NOT_VERIFY} are
 * derived/report states and must be non-selectable. Codes, labels, tones and
 * order are untouched; only {@code metadata_json.selectable} changes.</p>
 */
public class V135__Result_assessment_selectability extends BaseJavaMigration {

    private static final Set<String> DERIVED = Set.of(
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        List<ValueRow> rows = new ArrayList<>();
        try (PreparedStatement query = connection.prepareStatement("""
                SELECT v.id, v.code, v.metadata_json
                FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.code = 'RESULT'
                """)) {
            try (ResultSet result = query.executeQuery()) {
                while (result.next()) {
                    String code = result.getString("code");
                    if (DERIVED.contains(code)) {
                        rows.add(new ValueRow(result.getString("id"), code,
                                result.getString("metadata_json")));
                    }
                }
            }
        }
        if (rows.isEmpty()) {
            return;
        }
        try (PreparedStatement update = connection.prepareStatement("""
                UPDATE platform_option_values
                SET metadata_json = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """)) {
            for (ValueRow row : rows) {
                update.setString(1, nonSelectable(row.metadataJson()));
                update.setString(2, row.id());
                update.addBatch();
            }
            update.executeBatch();
        }
    }

    private String nonSelectable(String metadataJson) throws Exception {
        ObjectNode metadata = metadataJson == null || metadataJson.isBlank()
                ? objectMapper.createObjectNode()
                : (ObjectNode) objectMapper.readTree(metadataJson);
        metadata.put("selectable", false);
        return objectMapper.writeValueAsString(metadata);
    }

    private record ValueRow(String id, String code, String metadataJson) {
    }
}
