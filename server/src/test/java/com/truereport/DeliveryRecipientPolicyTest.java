package com.truereport;

import com.truereport.delivery.DeliveryRecipientPolicy;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class DeliveryRecipientPolicyTest {

    private final DeliveryRecipientPolicy policy = new DeliveryRecipientPolicy(
            "+971500009900", "private.9900@example.test", false);

    @Test
    void allowlistRejectsUnknownRecipientsAndMasksKnownOnes() {
        assertThat(policy.allowed("WHATSAPP", "+971 50 000 9900")).isTrue();
        assertThat(policy.allowed("SMS", "971500009900")).isTrue();
        assertThat(policy.allowed("EMAIL", "PRIVATE.9900@EXAMPLE.TEST")).isTrue();

        assertThat(policy.allowed("WHATSAPP", "+971500009901")).isFalse();
        assertThat(policy.allowed("EMAIL", "other@example.test")).isFalse();
        assertThat(policy.allowed("EMAIL", " ")).isFalse();

        assertThat(policy.masked("WHATSAPP", "+971500009900")).isEqualTo("***9900");
        assertThat(policy.masked("EMAIL", "private.9900@example.test"))
                .isEqualTo("p***@example.test");
    }

    @Test
    void explicitRealRecipientSwitchBypassesTheTestAllowlist() {
        DeliveryRecipientPolicy enabled = new DeliveryRecipientPolicy(
                "", "", true);
        assertThat(enabled.allowed("WHATSAPP", "+971500009901")).isTrue();
        assertThat(enabled.allowed("EMAIL", "other@example.test")).isTrue();
    }
}
