package com.truereport.shared.i18n;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Repository
public class TranslationGlossaryStore {

    public record Entry(String id, String sourceLang, String targetLang, String term,
                        String translation, boolean caseSensitive, boolean locked) {
    }

    private final JdbcTemplate jdbc;

    public TranslationGlossaryStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Entry> find(String sourceLang, String targetLang) {
        return jdbc.query("""
                SELECT id, source_lang, target_lang, term, translation,
                       case_sensitive, locked
                FROM translation_glossary
                WHERE source_lang = ? AND target_lang = ?
                ORDER BY length(term) DESC, term
                """, MAPPER, sourceLang, targetLang);
    }

    public List<Entry> findAll(String sourceLang, String targetLang) {
        if (sourceLang == null && targetLang == null) {
            return jdbc.query("""
                    SELECT id, source_lang, target_lang, term, translation,
                           case_sensitive, locked
                    FROM translation_glossary ORDER BY source_lang, target_lang, term
                    """, MAPPER);
        }
        List<Object> args = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
                SELECT id, source_lang, target_lang, term, translation,
                       case_sensitive, locked
                FROM translation_glossary WHERE 1 = 1
                """);
        if (sourceLang != null) {
            sql.append(" AND source_lang = ?");
            args.add(sourceLang);
        }
        if (targetLang != null) {
            sql.append(" AND target_lang = ?");
            args.add(targetLang);
        }
        sql.append(" ORDER BY source_lang, target_lang, term");
        return jdbc.query(sql.toString(), MAPPER, args.toArray());
    }

    public Optional<Entry> findById(String id) {
        return jdbc.query("""
                SELECT id, source_lang, target_lang, term, translation,
                       case_sensitive, locked
                FROM translation_glossary WHERE id = ?
                """, MAPPER, id).stream().findFirst();
    }

    public Entry insert(String sourceLang, String targetLang, String term, String translation,
                        boolean caseSensitive, boolean locked) {
        String id = com.truereport.shared.uuid.UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO translation_glossary
                    (id, source_lang, target_lang, term, translation, case_sensitive, locked,
                     created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, id, sourceLang, targetLang, term, translation, caseSensitive, locked);
        return findById(id).orElseThrow();
    }

    public void update(String id, String term, String translation, boolean caseSensitive,
                       boolean locked) {
        jdbc.update("""
                UPDATE translation_glossary
                SET term = ?, translation = ?, case_sensitive = ?, locked = ?
                WHERE id = ?
                """, term, translation, caseSensitive, locked, id);
    }

    public int delete(String id) {
        return jdbc.update("DELETE FROM translation_glossary WHERE id = ?", id);
    }

    /** Whole-word post-edit on provider output; longest terms first. */
    public String applyPostEdit(String text, List<Entry> entries) {
        String result = text == null ? "" : text;
        for (Entry entry : entries) {
            if (entry.locked() || entry.term() == null || entry.term().isBlank()) {
                continue;
            }
            Pattern pattern = Pattern.compile("\\b" + Pattern.quote(entry.term()) + "\\b",
                    entry.caseSensitive()
                            ? 0 : Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
            Matcher matcher = pattern.matcher(result);
            result = matcher.replaceAll(Matcher.quoteReplacement(entry.translation()));
        }
        return result;
    }

    private static final RowMapper<Entry> MAPPER = (rs, i) -> new Entry(
            rs.getString("id"), rs.getString("source_lang"), rs.getString("target_lang"),
            rs.getString("term"), rs.getString("translation"),
            rs.getBoolean("case_sensitive"), rs.getBoolean("locked"));
}
