package com.truereport.delivery;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

@Component
public class DeliveryRecipientPolicy {

    private final Set<String> phoneAllowlist = new HashSet<>();
    private final Set<String> emailAllowlist = new HashSet<>();
    private final boolean realRecipientsEnabled;

    public DeliveryRecipientPolicy(
            @Value("${truereport.delivery.allowed-phone-recipients:}") String phones,
            @Value("${truereport.delivery.allowed-email-recipients:}") String emails,
            @Value("${truereport.delivery.real-recipients-enabled:false}") boolean realRecipientsEnabled) {
        Arrays.stream(phones.split(",")).map(String::trim).filter(value -> !value.isBlank())
                .map(this::digits).forEach(phoneAllowlist::add);
        Arrays.stream(emails.split(",")).map(String::trim).filter(value -> !value.isBlank())
                .map(value -> value.toLowerCase()).forEach(emailAllowlist::add);
        this.realRecipientsEnabled = realRecipientsEnabled;
    }

    public boolean allowed(String channel, String recipient) {
        if (recipient == null || recipient.isBlank()) {
            return false;
        }
        if (realRecipientsEnabled) {
            return true;
        }
        if (channel.equals("EMAIL")) {
            return emailAllowlist.contains(recipient.trim().toLowerCase());
        }
        return phoneAllowlist.contains(digits(recipient));
    }

    public String masked(String channel, String recipient) {
        if (channel.equals("EMAIL")) {
            int at = recipient.indexOf('@');
            String local = at > 0 ? recipient.substring(0, 1) + "***" : "***";
            String domain = at >= 0 ? recipient.substring(at) : "";
            return local + domain;
        }
        String digits = digits(recipient);
        if (digits.length() <= 4) {
            return "***";
        }
        return "***" + digits.substring(digits.length() - 4);
    }

    public byte[] hash(String recipient) {
        try {
            String normalized = recipient.contains("@")
                    ? recipient.trim().toLowerCase() : digits(recipient);
            return MessageDigest.getInstance("SHA-256")
                    .digest(normalized.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("Cannot hash recipient", exception);
        }
    }

    private String digits(String value) {
        return value == null ? "" : value.replaceAll("[^0-9]", "");
    }

    public boolean isRealRecipientsEnabled() {
        return realRecipientsEnabled;
    }
}
