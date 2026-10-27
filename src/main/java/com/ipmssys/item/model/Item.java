package com.ipmssys.item.model;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.machine.model.Machine;

/**
 * An item (product) to be planned. The machines it is qualified to run on
 * come from the ITEM_MACHINE junction, loaded into {@code machines} for
 * display and serialized to JSON for the screen.
 */
public class Item implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer itemId;
    private String itemName;
    private String groupCode;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /** Qualified machines (from ITEM_MACHINE); display/read side. */
    private List<Machine> machines = new ArrayList<>();

    public Item() {
    }

    /** Duplicate check by name. */
    public Item(String itemName) {
        this.itemName = itemName;
    }

    /** Create / full save (machine links handled separately via the junction). */
    public Item(String itemName, String groupCode) {
        this.itemName = itemName;
        this.groupCode = groupCode;
    }

    public Integer getItemId() {
        return itemId;
    }

    public void setItemId(Integer itemId) {
        this.itemId = itemId;
    }

    public String getItemName() {
        return itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }

    public String getGroupCode() {
        return groupCode;
    }

    public void setGroupCode(String groupCode) {
        this.groupCode = groupCode;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<Machine> getMachines() {
        return machines;
    }

    public void setMachines(List<Machine> machines) {
        this.machines = machines;
    }
}
