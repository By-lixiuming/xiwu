# Xiwu 📦

[简体中文](README.md) | [繁體中文](README_zh_TW.md) | [English](README_en.md) | [日本語](README_ja.md)

> **Everything has a cost. Recognize real consumption. Cherish your items.**

"Xiwu" is a personal asset depreciation management tool that helps you track the depreciation of consumer goods, calculate the **average daily cost** of items, and make every expense clear.

## ✨ Features

- 📱 **Asset Entry & Management** — Quickly add your items, record purchase price, date, and category
- 📊 **Total Asset Dashboard** — View total asset residual value, total investment, and total depreciation at a glance
- 📉 **Three Depreciation Models** — Automatically calculate residual value changes based on item type
- 💰 **Average Daily Cost** — Calculate in real-time how much each item costs you every day
- 🎯 **Item Lifecycle** — Supports "Active" and "Sold/Retired" statuses
- 🎨 **Aesthetic Design** — Macaron color palette + Emoji icons + playful copy

## 🧮 Depreciation Models

| Model | Name | Logic | Scenarios |
|:---|:---|:---|:---|
| Model A | Linear Zeroing | Set expected lifespan, value linearly decreases to 0 | Consumables, Memberships |
| Model B | Drop & Decay | 20% drop on purchase, 15% annual decay thereafter | Electronics, Cars |
| Model C | Slow Decay / Value Preserving | Set a minimum residual value (e.g. 50%), slow depreciation until minimum | Luxury goods, Precious metals |

**Core Formula:**
```
Average Daily Cost = (Purchase Price - Current Residual Value) ÷ Days Owned
```
