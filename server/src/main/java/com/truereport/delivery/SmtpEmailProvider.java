package com.truereport.delivery;

import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@ConditionalOnProperty(name = "truereport.delivery.email-provider", havingValue = "smtp", matchIfMissing = true)
public class SmtpEmailProvider implements DeliveryProvider {

    private final JavaMailSender mailSender;
    private final String fromAddress;

    public SmtpEmailProvider(JavaMailSender mailSender,
                             @Value("${truereport.delivery.from-address:reports@truereport.local}")
                             String fromAddress) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
    }

    @Override
    public String name() {
        return "smtp";
    }

    @Override
    public DeliveryResult send(DeliveryMessage message) {
        try {
            MimeMessage mime = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mime, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(message.recipient());
            helper.setSubject(message.subject());
            helper.setText(message.body(), false);
            if (message.pdf() != null && message.pdf().length > 0) {
                helper.addAttachment(message.pdfFilename(),
                        new ByteArrayResource(message.pdf()));
            }
            mailSender.send(mime);
            return DeliveryResult.sent("smtp-" + UUID.randomUUID());
        } catch (MailException | jakarta.mail.MessagingException exception) {
            return DeliveryResult.failed("SMTP_FAILED", "SMTP delivery failed");
        }
    }
}
