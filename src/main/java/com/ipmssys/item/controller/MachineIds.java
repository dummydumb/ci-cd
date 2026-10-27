package com.ipmssys.item.controller;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;

/**
 * Parses the qualified-machine ids from the request. Accepts either repeated
 * {@code machineids} parameters or a single comma-separated value (Selectize
 * posts comma-separated by default). Duplicates and blanks are dropped.
 */
final class MachineIds {

    private MachineIds() {
    }

    static int[] from(HttpServletRequest request) {
        Set<Integer> ids = new LinkedHashSet<>();

        String[] values = request.getParameterValues("machineids");
        if (values != null) {
            for (String value : values) {
                addAll(ids, value);
            }
        }
        return toArray(ids);
    }

    private static void addAll(Set<Integer> ids, String raw) {
        if (raw == null) {
            return;
        }
        String[] parts = raw.split(",");
        for (String part : parts) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                try {
                    ids.add(Integer.valueOf(trimmed));
                } catch (NumberFormatException ignored) {
                    // skip non-numeric tokens
                }
            }
        }
    }

    private static int[] toArray(Set<Integer> ids) {
        List<Integer> list = new ArrayList<>(ids);
        int[] result = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            result[i] = list.get(i);
        }
        return result;
    }
}
