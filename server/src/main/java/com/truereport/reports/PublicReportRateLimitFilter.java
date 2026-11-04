package com.truereport.reports;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class PublicReportRateLimitFilter extends OncePerRequestFilter {

    private static final int LIMIT = 240;
    private static final long WINDOW_MILLIS = 60_000;
    private final Map<String, Deque<Long>> hits = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/r/")
                || request.getRequestURI().startsWith("/r/assets/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String key = clientIp(request);
        long now = System.currentTimeMillis();
        Deque<Long> values = hits.computeIfAbsent(key, ignored -> new ArrayDeque<>());
        synchronized (values) {
            while (!values.isEmpty() && values.peekFirst() < now - WINDOW_MILLIS) {
                values.removeFirst();
            }
            if (values.size() >= LIMIT) {
                response.setStatus(429);
                response.setHeader("Retry-After", "60");
                response.setContentType("text/html;charset=UTF-8");
                response.getWriter().write(neutralPage());
                return;
            }
            values.addLast(now);
        }
        filterChain.doFilter(request, response);
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String neutralPage() {
        String html = "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
                + "<meta name=\"robots\" content=\"noindex,nofollow\"><title>Link unavailable</title></head>"
                + "<body><main><h1>This link is unavailable</h1>"
                + "<p>Please try again later.</p></main></body></html>";
        return new String(html.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
    }
}
