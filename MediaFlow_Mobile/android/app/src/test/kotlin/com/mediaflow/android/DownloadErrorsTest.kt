package com.mediaflow.android

import org.junit.Assert.*
import org.junit.Test

class DownloadErrorsTest {
    @Test fun unsafeLinkSchemesAreRejected() {
        listOf("file:///data/local", "ftp://example.com/a", "javascript:alert(1)", "https://user:secret@example.com", "bad link").forEach {
            assertThrows(IllegalArgumentException::class.java) { DownloadErrors.validateUrl(it) }
        }
        assertEquals("https://example.com/a?x=1", DownloadErrors.validateUrl(" https://example.com/a?x=1 "))
    }

    @Test fun credentialsDoNotAppearInErrorDetails() {
        val result = DownloadErrors.redact("Failed https://example.com/a?token=secret\nAuthorization: Bearer private")
        assertFalse(result.contains("secret"))
        assertFalse(result.contains("private"))
    }

    @Test fun sourceAndDiskFailuresHaveDifferentRecoveryActions() {
        assertEquals("DISK_FULL", DownloadErrors.classify(Exception("ENOSPC: No space left")).code)
        assertEquals("LOGIN_REQUIRED", DownloadErrors.classify(Exception("Login required")).code)
        assertEquals("RATE_LIMIT", DownloadErrors.classify(Exception("HTTP 429")).code)
        assertEquals("ACCESS_DENIED", DownloadErrors.classify(Exception("HTTP 403 Forbidden")).code)
    }
}
