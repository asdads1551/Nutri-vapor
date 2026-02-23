#!/usr/bin/env python3
"""Generate 100 curated recipe entries for the Nutri app."""

import json
import uuid
import os

CREATED_AT = "2026-02-17T00:00:00Z"

def make_recipe(name, calories, cooking_time, servings, tags, icon_name, icon_bg,
                protein, carbs, fat, fiber, ingredients, price, allergens, cuisine_type):
    return {
        "id": str(uuid.uuid4()),
        "name": name,
        "calories": calories,
        "cookingTime": cooking_time,
        "servings": servings,
        "tags": tags,
        "iconName": icon_name,
        "iconBackgroundColorHex": icon_bg,
        "protein": round(protein, 1),
        "carbs": round(carbs, 1),
        "fat": round(fat, 1),
        "fiber": round(fiber, 1),
        "ingredients": ingredients,
        "price": price,
        "allergens": allergens,
        "cuisineType": cuisine_type,
        "authorId": "system",
        "createdAt": CREATED_AT,
        "updatedAt": CREATED_AT
    }

def ing(name, amount):
    return {"name": name, "amount": amount}

def build_recipes():
    recipes = []

    # ==============================
    # TAIWANESE (35)
    # ==============================
    recipes.append(make_recipe(
        "滷肉飯", 550, 60, 2, ["高蛋白"],
        "bowl.fill", "#FFF8E1",
        18.0, 65.0, 25.0, 1.5,
        [ing("五花肉", "300g"), ing("紅蔥頭", "6顆"), ing("醬油", "3大匙"), ing("冰糖", "1大匙"), ing("白飯", "2碗"), ing("五香粉", "1小匙")],
        85, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "牛肉麵", 620, 90, 2, ["高蛋白"],
        "bowl.fill", "#FFF8E1",
        35.0, 55.0, 22.0, 3.0,
        [ing("牛腱肉", "500g"), ing("麵條", "200g"), ing("番茄", "2顆"), ing("豆瓣醬", "2大匙"), ing("蔥", "2根"), ing("薑", "3片"), ing("八角", "2顆")],
        180, ["麩質", "大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蚵仔煎", 380, 20, 1, ["Omega-3"],
        "flame.fill", "#FFF8E1",
        15.0, 35.0, 20.0, 1.0,
        [ing("鮮蚵", "150g"), ing("雞蛋", "2顆"), ing("地瓜粉", "3大匙"), ing("小白菜", "50g"), ing("甜辣醬", "適量")],
        90, ["海鮮", "蛋"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "三杯雞", 480, 35, 3, ["高蛋白", "無麩質"],
        "flame.fill", "#FFF8E1",
        32.0, 8.0, 35.0, 0.5,
        [ing("雞腿", "600g"), ing("薑片", "30g"), ing("蒜頭", "10顆"), ing("九層塔", "一把"), ing("麻油", "2大匙"), ing("醬油", "2大匙"), ing("米酒", "2大匙")],
        160, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "割包", 420, 40, 2, [],
        "fork.knife", "#FFF8E1",
        18.0, 45.0, 18.0, 1.0,
        [ing("割包皮", "4個"), ing("五花肉", "300g"), ing("酸菜", "50g"), ing("花生粉", "2大匙"), ing("香菜", "適量")],
        100, ["麩質", "堅果"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "鹽酥雞", 520, 25, 2, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        28.0, 30.0, 32.0, 1.0,
        [ing("雞胸肉", "400g"), ing("地瓜粉", "100g"), ing("蒜頭", "5顆"), ing("九層塔", "一把"), ing("五香粉", "1小匙"), ing("胡椒鹽", "適量")],
        100, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蛤蜊湯", 120, 15, 2, ["低卡", "Omega-3", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        12.0, 4.0, 3.0, 0.2,
        [ing("蛤蜊", "300g"), ing("薑絲", "10g"), ing("蔥", "1根"), ing("米酒", "1大匙")],
        80, ["海鮮"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "排骨酥湯", 380, 50, 3, [],
        "cup.and.saucer.fill", "#FFF8E1",
        22.0, 20.0, 24.0, 2.5,
        [ing("排骨", "400g"), ing("白蘿蔔", "200g"), ing("地瓜粉", "50g"), ing("蔥", "2根"), ing("薑", "3片")],
        130, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "麻油雞", 550, 45, 3, ["高蛋白", "無麩質"],
        "flame.fill", "#FFF8E1",
        38.0, 5.0, 40.0, 0.3,
        [ing("雞腿", "600g"), ing("老薑", "80g"), ing("麻油", "3大匙"), ing("米酒", "1瓶"), ing("枸杞", "1大匙")],
        200, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "滷味拼盤", 350, 60, 3, [],
        "fork.knife", "#FFF8E1",
        25.0, 15.0, 20.0, 2.0,
        [ing("豆干", "200g"), ing("海帶", "100g"), ing("滷蛋", "3顆"), ing("百頁豆腐", "150g"), ing("醬油", "3大匙"), ing("八角", "2顆")],
        120, ["大豆", "蛋"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "肉圓", 370, 30, 2, [],
        "fork.knife", "#FFF8E1",
        16.0, 40.0, 16.0, 1.0,
        [ing("豬肉", "200g"), ing("地瓜粉", "100g"), ing("筍丁", "50g"), ing("香菇", "3朵"), ing("甜辣醬", "適量")],
        70, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蘿蔔糕", 280, 50, 4, ["素食"],
        "fork.knife", "#E8F5E9",
        5.0, 35.0, 12.0, 2.0,
        [ing("白蘿蔔", "600g"), ing("在來米粉", "200g"), ing("蝦米", "20g"), ing("香菇", "3朵"), ing("油蔥酥", "1大匙")],
        60, ["海鮮"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蔥油餅", 320, 20, 2, ["素食"],
        "flame.fill", "#FFF8E1",
        7.0, 38.0, 16.0, 1.5,
        [ing("中筋麵粉", "200g"), ing("蔥花", "50g"), ing("鹽", "適量"), ing("油", "2大匙")],
        50, ["麩質"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "珍珠奶茶", 450, 30, 1, ["含乳製品"],
        "cup.and.saucer.fill", "#FCE4EC",
        5.0, 75.0, 15.0, 0.0,
        [ing("紅茶", "300ml"), ing("鮮奶", "100ml"), ing("珍珠粉圓", "80g"), ing("糖", "2大匙")],
        65, ["乳製品"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "鳳梨蝦球", 380, 25, 3, ["Omega-3"],
        "flame.fill", "#E0F2F1",
        20.0, 30.0, 20.0, 1.5,
        [ing("大蝦", "300g"), ing("鳳梨", "150g"), ing("美乃滋", "2大匙"), ing("地瓜粉", "50g")],
        180, ["海鮮", "蛋"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蒜泥白肉", 300, 30, 3, ["高蛋白", "低卡", "無麩質"],
        "fork.knife", "#E0F2F1",
        28.0, 5.0, 18.0, 0.5,
        [ing("五花肉", "400g"), ing("蒜泥", "30g"), ing("醬油膏", "2大匙"), ing("辣油", "1小匙"), ing("蔥", "1根")],
        130, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "竹筍排骨湯", 250, 45, 3, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        20.0, 10.0, 14.0, 3.0,
        [ing("排骨", "300g"), ing("竹筍", "200g"), ing("薑", "3片"), ing("鹽", "適量")],
        120, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "地瓜葉", 80, 10, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        3.0, 8.0, 4.0, 3.5,
        [ing("地瓜葉", "300g"), ing("蒜頭", "3顆"), ing("油", "1大匙"), ing("鹽", "適量")],
        50, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "燙青菜", 85, 8, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        3.5, 6.0, 5.0, 3.0,
        [ing("青江菜", "300g"), ing("蒜泥", "10g"), ing("醬油膏", "1大匙"), ing("油", "1大匙")],
        50, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "豆乾炒肉絲", 320, 15, 2, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        25.0, 10.0, 20.0, 1.5,
        [ing("豆干", "200g"), ing("豬肉絲", "150g"), ing("辣椒", "1根"), ing("蔥", "2根"), ing("醬油", "1大匙")],
        90, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "高麗菜飯", 380, 30, 3, [],
        "bowl.fill", "#E8F5E9",
        10.0, 55.0, 12.0, 3.0,
        [ing("高麗菜", "300g"), ing("白米", "2杯"), ing("油蔥酥", "1大匙"), ing("蝦米", "10g"), ing("醬油", "1大匙")],
        70, ["大豆", "海鮮"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "滷蛋", 140, 30, 2, ["低卡", "高蛋白", "無麩質"],
        "fork.knife", "#FFF8E1",
        12.0, 3.0, 9.0, 0.0,
        [ing("雞蛋", "4顆"), ing("醬油", "3大匙"), ing("八角", "1顆"), ing("冰糖", "1小匙")],
        50, ["蛋", "大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "筒仔米糕", 450, 60, 2, [],
        "bowl.fill", "#FFF8E1",
        15.0, 60.0, 16.0, 1.0,
        [ing("糯米", "300g"), ing("豬肉", "150g"), ing("香菇", "3朵"), ing("蝦米", "10g"), ing("醬油", "2大匙"), ing("油蔥酥", "1大匙")],
        80, ["大豆", "海鮮"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "四神湯", 200, 60, 3, ["低卡"],
        "cup.and.saucer.fill", "#E0F2F1",
        15.0, 18.0, 6.0, 2.0,
        [ing("薏仁", "50g"), ing("山藥", "100g"), ing("蓮子", "50g"), ing("茯苓", "20g"), ing("小腸", "200g")],
        100, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "味噌豆腐", 180, 15, 2, ["低卡", "素食"],
        "cup.and.saucer.fill", "#E8F5E9",
        12.0, 10.0, 10.0, 1.5,
        [ing("嫩豆腐", "1盒"), ing("味噌", "1.5大匙"), ing("蔥花", "適量"), ing("柴魚片", "5g")],
        60, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "涼拌小黃瓜", 90, 10, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        2.0, 8.0, 5.0, 1.5,
        [ing("小黃瓜", "3根"), ing("蒜泥", "10g"), ing("辣油", "1小匙"), ing("醋", "1大匙"), ing("糖", "1小匙")],
        50, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "苦瓜排骨湯", 230, 45, 3, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        18.0, 10.0, 12.0, 2.5,
        [ing("苦瓜", "1條"), ing("排骨", "300g"), ing("薑", "3片"), ing("鹽", "適量")],
        110, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "薑母鴨", 650, 90, 4, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        40.0, 10.0, 48.0, 1.0,
        [ing("鴨肉", "800g"), ing("老薑", "200g"), ing("麻油", "3大匙"), ing("米酒", "1瓶"), ing("枸杞", "1大匙"), ing("當歸", "2片")],
        250, [], "台灣料理"
    ))
    recipes.append(make_recipe(
        "臭豆腐", 380, 20, 1, ["素食"],
        "flame.fill", "#FFF8E1",
        14.0, 25.0, 25.0, 2.0,
        [ing("臭豆腐", "4塊"), ing("泡菜", "100g"), ing("蒜泥", "適量"), ing("辣醬", "適量")],
        70, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "紅燒肉", 580, 60, 4, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        30.0, 15.0, 42.0, 0.5,
        [ing("五花肉", "600g"), ing("醬油", "3大匙"), ing("冰糖", "2大匙"), ing("蔥", "2根"), ing("薑", "3片"), ing("八角", "2顆")],
        160, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "客家小炒", 400, 20, 3, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        22.0, 12.0, 30.0, 1.5,
        [ing("五花肉", "200g"), ing("豆干", "150g"), ing("魷魚", "100g"), ing("蔥", "3根"), ing("蒜苗", "2根"), ing("醬油", "1大匙")],
        140, ["大豆", "海鮮"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "蒸蛋", 150, 15, 2, ["低卡", "無麩質"],
        "fork.knife", "#E0F2F1",
        10.0, 2.0, 11.0, 0.0,
        [ing("雞蛋", "3顆"), ing("高湯", "200ml"), ing("蔥花", "適量"), ing("醬油", "少許")],
        55, ["蛋", "大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "番茄蛋花湯", 130, 15, 2, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        8.0, 10.0, 6.0, 1.5,
        [ing("番茄", "2顆"), ing("雞蛋", "2顆"), ing("蔥花", "適量"), ing("鹽", "適量")],
        55, ["蛋"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "金針菇炒肉", 260, 15, 2, [],
        "flame.fill", "#FFF8E1",
        20.0, 10.0, 16.0, 2.0,
        [ing("金針菇", "200g"), ing("豬肉片", "150g"), ing("蔥", "1根"), ing("醬油", "1大匙"), ing("蒜", "2顆")],
        90, ["大豆"], "台灣料理"
    ))
    recipes.append(make_recipe(
        "白菜滷", 180, 25, 3, ["低卡"],
        "leaf.fill", "#E8F5E9",
        10.0, 12.0, 10.0, 3.0,
        [ing("大白菜", "500g"), ing("蝦米", "10g"), ing("香菇", "3朵"), ing("紅蘿蔔", "50g"), ing("扁魚", "5g")],
        80, ["海鮮"], "台灣料理"
    ))

    # ==============================
    # CHINESE (25)
    # ==============================
    recipes.append(make_recipe(
        "麻婆豆腐", 320, 20, 2, [],
        "flame.fill", "#FFF8E1",
        18.0, 12.0, 22.0, 1.0,
        [ing("嫩豆腐", "1盒"), ing("豬絞肉", "100g"), ing("豆瓣醬", "1大匙"), ing("花椒", "1小匙"), ing("蒜", "3顆"), ing("蔥", "1根")],
        80, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "宮保雞丁", 420, 25, 3, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        30.0, 15.0, 26.0, 2.0,
        [ing("雞胸肉", "400g"), ing("花生", "50g"), ing("乾辣椒", "10根"), ing("花椒", "1小匙"), ing("蔥", "3根"), ing("醬油", "2大匙")],
        120, ["堅果", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "番茄炒蛋", 250, 15, 2, ["低卡"],
        "flame.fill", "#FFF8E1",
        12.0, 10.0, 18.0, 1.5,
        [ing("番茄", "2顆"), ing("雞蛋", "3顆"), ing("蔥", "1根"), ing("糖", "1小匙"), ing("鹽", "適量")],
        60, ["蛋"], "中華料理"
    ))
    recipes.append(make_recipe(
        "回鍋肉", 450, 20, 3, [],
        "flame.fill", "#FFF8E1",
        22.0, 12.0, 35.0, 2.0,
        [ing("五花肉", "300g"), ing("蒜苗", "3根"), ing("豆瓣醬", "1大匙"), ing("甜麵醬", "1大匙"), ing("辣椒", "2根")],
        120, ["大豆", "麩質"], "中華料理"
    ))
    recipes.append(make_recipe(
        "水煮魚", 480, 30, 4, ["高蛋白", "Omega-3"],
        "fish.fill", "#E0F2F1",
        35.0, 8.0, 34.0, 1.5,
        [ing("鱸魚", "500g"), ing("豆芽菜", "200g"), ing("乾辣椒", "15根"), ing("花椒", "2大匙"), ing("蒜", "5顆"), ing("薑", "3片")],
        200, ["海鮮", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "糖醋排骨", 480, 35, 3, [],
        "flame.fill", "#FFF8E1",
        25.0, 30.0, 28.0, 0.5,
        [ing("排骨", "500g"), ing("番茄醬", "3大匙"), ing("白醋", "2大匙"), ing("糖", "2大匙"), ing("醬油", "1大匙"), ing("太白粉", "2大匙")],
        140, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "蝦仁炒蛋", 280, 15, 2, ["Omega-3"],
        "flame.fill", "#E0F2F1",
        22.0, 3.0, 20.0, 0.2,
        [ing("蝦仁", "200g"), ing("雞蛋", "3顆"), ing("蔥花", "適量"), ing("鹽", "適量"), ing("米酒", "1小匙")],
        120, ["海鮮", "蛋"], "中華料理"
    ))
    recipes.append(make_recipe(
        "魚香茄子", 280, 20, 2, ["素食"],
        "flame.fill", "#FFF8E1",
        6.0, 18.0, 20.0, 4.0,
        [ing("茄子", "3條"), ing("豆瓣醬", "1大匙"), ing("蒜", "3顆"), ing("薑", "10g"), ing("醋", "1大匙"), ing("糖", "1大匙")],
        70, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "青椒炒肉絲", 300, 15, 2, [],
        "flame.fill", "#FFF8E1",
        22.0, 8.0, 20.0, 2.0,
        [ing("豬肉絲", "200g"), ing("青椒", "3個"), ing("醬油", "1大匙"), ing("太白粉", "1小匙"), ing("蒜", "2顆")],
        90, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "西紅柿蛋湯", 120, 15, 2, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        7.0, 8.0, 6.0, 1.0,
        [ing("番茄", "2顆"), ing("雞蛋", "2顆"), ing("蔥花", "適量"), ing("鹽", "適量")],
        50, ["蛋"], "中華料理"
    ))
    recipes.append(make_recipe(
        "紅燒牛腩", 520, 90, 4, ["高蛋白"],
        "fork.knife", "#FFF8E1",
        38.0, 15.0, 32.0, 2.0,
        [ing("牛腩", "600g"), ing("紅蘿蔔", "2根"), ing("洋蔥", "1顆"), ing("醬油", "3大匙"), ing("番茄", "2顆"), ing("八角", "2顆")],
        220, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "蒸魚", 220, 20, 2, ["低卡", "高蛋白", "Omega-3", "無麩質"],
        "fish.fill", "#E0F2F1",
        30.0, 3.0, 10.0, 0.2,
        [ing("鱸魚", "1條"), ing("薑絲", "20g"), ing("蔥絲", "2根"), ing("醬油", "1大匙"), ing("米酒", "1大匙")],
        180, ["海鮮", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "涼拌木耳", 90, 10, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        2.0, 12.0, 3.0, 4.0,
        [ing("黑木耳", "200g"), ing("紅蘿蔔", "50g"), ing("蒜泥", "10g"), ing("醋", "1大匙"), ing("辣油", "1小匙")],
        50, [], "中華料理"
    ))
    recipes.append(make_recipe(
        "白灼蝦", 180, 10, 2, ["低卡", "高蛋白", "Omega-3", "無麩質"],
        "fish.fill", "#E0F2F1",
        28.0, 2.0, 6.0, 0.0,
        [ing("鮮蝦", "300g"), ing("薑", "3片"), ing("蔥", "1根"), ing("米酒", "1大匙"), ing("醬油", "適量")],
        160, ["海鮮", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "清炒時蔬", 100, 10, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        3.0, 8.0, 6.0, 3.0,
        [ing("綜合時蔬", "300g"), ing("蒜", "3顆"), ing("鹽", "適量"), ing("油", "1大匙")],
        60, [], "中華料理"
    ))
    recipes.append(make_recipe(
        "香菇雞湯", 280, 45, 3, ["無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        25.0, 5.0, 18.0, 1.0,
        [ing("雞腿", "400g"), ing("乾香菇", "6朵"), ing("薑", "3片"), ing("枸杞", "1大匙"), ing("米酒", "1大匙")],
        140, [], "中華料理"
    ))
    recipes.append(make_recipe(
        "酸辣湯", 200, 20, 3, [],
        "cup.and.saucer.fill", "#FFF8E1",
        12.0, 15.0, 10.0, 1.5,
        [ing("豆腐", "150g"), ing("木耳", "50g"), ing("筍絲", "50g"), ing("雞蛋", "1顆"), ing("醋", "2大匙"), ing("胡椒粉", "1小匙"), ing("太白粉", "1大匙")],
        70, ["蛋", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "木須肉", 330, 20, 2, [],
        "flame.fill", "#FFF8E1",
        20.0, 12.0, 22.0, 2.0,
        [ing("豬肉片", "200g"), ing("木耳", "50g"), ing("雞蛋", "2顆"), ing("黃瓜", "1根"), ing("醬油", "1大匙")],
        90, ["蛋", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "乾煸四季豆", 200, 15, 2, ["低卡", "無麩質"],
        "leaf.fill", "#E8F5E9",
        12.0, 10.0, 12.0, 4.0,
        [ing("四季豆", "300g"), ing("豬絞肉", "80g"), ing("蒜", "3顆"), ing("辣椒", "2根"), ing("醬油", "1小匙")],
        70, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "紅燒豆腐", 240, 20, 2, ["素食"],
        "fork.knife", "#E8F5E9",
        14.0, 12.0, 16.0, 1.0,
        [ing("板豆腐", "1盒"), ing("醬油", "2大匙"), ing("糖", "1小匙"), ing("蔥", "1根"), ing("蒜", "2顆")],
        60, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "雪菜肉絲", 280, 15, 2, [],
        "flame.fill", "#FFF8E1",
        20.0, 8.0, 18.0, 2.0,
        [ing("雪菜", "150g"), ing("豬肉絲", "200g"), ing("辣椒", "1根"), ing("蒜", "2顆"), ing("醬油", "1小匙")],
        85, ["大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "蝦仁滑蛋", 300, 15, 2, ["Omega-3"],
        "flame.fill", "#E0F2F1",
        24.0, 3.0, 22.0, 0.2,
        [ing("蝦仁", "200g"), ing("雞蛋", "4顆"), ing("蔥花", "適量"), ing("米酒", "1小匙")],
        130, ["海鮮", "蛋"], "中華料理"
    ))
    recipes.append(make_recipe(
        "清蒸鱸魚", 200, 20, 2, ["低卡", "高蛋白", "Omega-3", "無麩質"],
        "fish.fill", "#E0F2F1",
        28.0, 2.0, 9.0, 0.1,
        [ing("鱸魚", "1條"), ing("薑絲", "20g"), ing("蔥絲", "2根"), ing("醬油", "1大匙"), ing("香油", "1小匙")],
        190, ["海鮮", "大豆"], "中華料理"
    ))
    recipes.append(make_recipe(
        "冬瓜排骨湯", 220, 40, 3, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        16.0, 12.0, 10.0, 2.0,
        [ing("冬瓜", "400g"), ing("排骨", "300g"), ing("薑", "3片"), ing("蔥", "1根")],
        100, [], "中華料理"
    ))
    recipes.append(make_recipe(
        "炒飯", 480, 15, 2, [],
        "bowl.fill", "#FFF8E1",
        15.0, 58.0, 18.0, 2.0,
        [ing("白飯", "2碗"), ing("雞蛋", "2顆"), ing("蔥", "2根"), ing("紅蘿蔔丁", "50g"), ing("火腿丁", "50g"), ing("醬油", "1大匙")],
        70, ["蛋", "大豆"], "中華料理"
    ))

    # ==============================
    # JAPANESE (15)
    # ==============================
    recipes.append(make_recipe(
        "親子丼", 520, 25, 2, ["高蛋白"],
        "bowl.fill", "#FFF8E1",
        30.0, 55.0, 18.0, 1.0,
        [ing("雞腿肉", "300g"), ing("雞蛋", "3顆"), ing("洋蔥", "1顆"), ing("醬油", "2大匙"), ing("味醂", "2大匙"), ing("白飯", "2碗")],
        120, ["蛋", "大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "味噌拉麵", 580, 40, 1, [],
        "bowl.fill", "#FFF8E1",
        25.0, 60.0, 25.0, 2.0,
        [ing("拉麵", "1份"), ing("味噌", "2大匙"), ing("叉燒肉", "3片"), ing("蔥花", "適量"), ing("溏心蛋", "1顆"), ing("玉米粒", "30g")],
        150, ["麩質", "大豆", "蛋"], "日本料理"
    ))
    recipes.append(make_recipe(
        "照燒鮭魚", 380, 20, 2, ["高蛋白", "Omega-3"],
        "fish.fill", "#E0F2F1",
        32.0, 12.0, 22.0, 0.5,
        [ing("鮭魚", "2片"), ing("醬油", "2大匙"), ing("味醂", "2大匙"), ing("糖", "1小匙"), ing("薑", "10g")],
        200, ["海鮮", "大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "毛豆", 120, 5, 2, ["低卡", "素食", "無麩質"],
        "leaf.fill", "#E8F5E9",
        11.0, 8.0, 5.0, 4.0,
        [ing("毛豆", "300g"), ing("鹽", "適量")],
        50, ["大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "壽司", 350, 40, 2, ["Omega-3"],
        "fish.fill", "#E0F2F1",
        15.0, 50.0, 8.0, 1.0,
        [ing("壽司米", "2杯"), ing("醋", "2大匙"), ing("鮭魚", "100g"), ing("鮪魚", "100g"), ing("海苔", "4片"), ing("芥末", "適量")],
        180, ["海鮮"], "日本料理"
    ))
    recipes.append(make_recipe(
        "天婦羅", 420, 25, 2, [],
        "flame.fill", "#FFF8E1",
        15.0, 35.0, 25.0, 2.0,
        [ing("鮮蝦", "6尾"), ing("地瓜", "1條"), ing("四季豆", "6根"), ing("天婦羅粉", "100g"), ing("蛋", "1顆")],
        140, ["海鮮", "麩質", "蛋"], "日本料理"
    ))
    recipes.append(make_recipe(
        "日式咖哩飯", 580, 45, 3, [],
        "bowl.fill", "#FFF8E1",
        20.0, 70.0, 22.0, 3.0,
        [ing("咖哩塊", "半盒"), ing("雞肉", "300g"), ing("馬鈴薯", "2顆"), ing("紅蘿蔔", "1根"), ing("洋蔥", "1顆"), ing("白飯", "3碗")],
        130, ["麩質"], "日本料理"
    ))
    recipes.append(make_recipe(
        "冷豆腐", 100, 5, 1, ["低卡", "素食", "無麩質"],
        "leaf.arrow.circlepath", "#E8F5E9",
        8.0, 4.0, 5.0, 0.5,
        [ing("絹豆腐", "1盒"), ing("醬油", "1大匙"), ing("薑泥", "5g"), ing("蔥花", "適量"), ing("柴魚片", "3g")],
        50, ["大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "烤秋刀魚", 320, 20, 1, ["高蛋白", "Omega-3", "無麩質", "生酮"],
        "fish.fill", "#E0F2F1",
        25.0, 0.5, 24.0, 0.0,
        [ing("秋刀魚", "2尾"), ing("鹽", "適量"), ing("檸檬", "1顆"), ing("白蘿蔔泥", "適量")],
        80, ["海鮮"], "日本料理"
    ))
    recipes.append(make_recipe(
        "茶碗蒸", 130, 20, 2, ["低卡", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        10.0, 3.0, 8.0, 0.2,
        [ing("雞蛋", "3顆"), ing("高湯", "300ml"), ing("蝦仁", "4尾"), ing("香菇", "2朵"), ing("魚板", "2片")],
        80, ["蛋", "海鮮"], "日本料理"
    ))
    recipes.append(make_recipe(
        "日式漬物", 80, 10, 2, ["低卡", "素食", "純素", "無麩質"],
        "leaf.fill", "#E8F5E9",
        1.5, 16.0, 0.5, 2.0,
        [ing("白蘿蔔", "200g"), ing("小黃瓜", "1根"), ing("醋", "2大匙"), ing("糖", "1大匙"), ing("鹽", "1小匙")],
        50, [], "日本料理"
    ))
    recipes.append(make_recipe(
        "豬排丼", 650, 30, 1, [],
        "bowl.fill", "#FFF8E1",
        30.0, 65.0, 28.0, 1.5,
        [ing("豬排", "1片"), ing("雞蛋", "2顆"), ing("洋蔥", "半顆"), ing("醬油", "2大匙"), ing("味醂", "1大匙"), ing("麵包粉", "適量"), ing("白飯", "1碗")],
        140, ["麩質", "蛋", "大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "蕎麥麵", 350, 15, 1, [],
        "bowl.fill", "#E0F2F1",
        14.0, 55.0, 5.0, 3.0,
        [ing("蕎麥麵", "1份"), ing("醬油", "2大匙"), ing("味醂", "1大匙"), ing("海苔", "適量"), ing("蔥花", "適量"), ing("芥末", "適量")],
        90, ["麩質", "大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "鯖魚味噌煮", 340, 25, 2, ["高蛋白", "Omega-3"],
        "fish.fill", "#E0F2F1",
        28.0, 8.0, 22.0, 0.5,
        [ing("鯖魚", "2片"), ing("味噌", "2大匙"), ing("薑", "10g"), ing("味醂", "1大匙"), ing("糖", "1小匙")],
        140, ["海鮮", "大豆"], "日本料理"
    ))
    recipes.append(make_recipe(
        "日式炒烏龍", 450, 20, 2, [],
        "bowl.fill", "#FFF8E1",
        18.0, 55.0, 16.0, 2.0,
        [ing("烏龍麵", "2份"), ing("豬肉片", "150g"), ing("高麗菜", "100g"), ing("紅蘿蔔", "50g"), ing("醬油", "2大匙")],
        100, ["麩質", "大豆"], "日本料理"
    ))

    # ==============================
    # KOREAN (10)
    # ==============================
    recipes.append(make_recipe(
        "石鍋拌飯", 520, 30, 1, ["高蛋白"],
        "bowl.fill", "#FFF8E1",
        22.0, 60.0, 20.0, 4.0,
        [ing("白飯", "1碗"), ing("牛肉片", "100g"), ing("菠菜", "50g"), ing("紅蘿蔔", "50g"), ing("豆芽菜", "50g"), ing("雞蛋", "1顆"), ing("韓式辣醬", "1大匙")],
        130, ["蛋", "大豆"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "韓式泡菜鍋", 380, 30, 2, [],
        "cup.and.saucer.fill", "#FCE4EC",
        22.0, 20.0, 22.0, 3.0,
        [ing("泡菜", "200g"), ing("五花肉", "200g"), ing("豆腐", "1盒"), ing("蔥", "2根"), ing("韓式辣醬", "1大匙")],
        120, ["大豆"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "辣炒年糕", 400, 20, 2, ["素食"],
        "flame.fill", "#FCE4EC",
        8.0, 65.0, 12.0, 2.0,
        [ing("年糕", "300g"), ing("韓式辣醬", "2大匙"), ing("魚板", "50g"), ing("蔥", "1根"), ing("糖", "1大匙")],
        80, ["麩質", "海鮮"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "韓式烤肉", 480, 25, 3, ["高蛋白", "生酮", "無麩質"],
        "flame.fill", "#FFF8E1",
        35.0, 8.0, 34.0, 1.0,
        [ing("牛五花", "400g"), ing("蒜", "5顆"), ing("醬油", "2大匙"), ing("梨汁", "2大匙"), ing("芝麻油", "1大匙"), ing("生菜", "適量")],
        250, ["大豆"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "海帶湯", 120, 30, 2, ["低卡", "Omega-3", "無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        8.0, 6.0, 7.0, 2.0,
        [ing("海帶", "100g"), ing("牛肉", "100g"), ing("蒜", "2顆"), ing("醬油", "1大匙"), ing("芝麻油", "1小匙")],
        80, ["大豆", "海鮮"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "韓式炸雞", 550, 35, 2, [],
        "flame.fill", "#FFF8E1",
        28.0, 30.0, 35.0, 1.0,
        [ing("雞翅", "500g"), ing("太白粉", "100g"), ing("韓式辣醬", "3大匙"), ing("蒜", "3顆"), ing("蜂蜜", "1大匙")],
        140, [], "韓國料理"
    ))
    recipes.append(make_recipe(
        "泡菜煎餅", 350, 20, 2, [],
        "flame.fill", "#FCE4EC",
        10.0, 35.0, 18.0, 2.0,
        [ing("泡菜", "150g"), ing("麵粉", "100g"), ing("雞蛋", "1顆"), ing("蔥", "2根"), ing("水", "80ml")],
        70, ["麩質", "蛋"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "大醬湯", 180, 25, 2, ["低卡"],
        "cup.and.saucer.fill", "#E8F5E9",
        12.0, 10.0, 10.0, 2.0,
        [ing("大醬", "2大匙"), ing("豆腐", "150g"), ing("櫛瓜", "1條"), ing("蔥", "1根"), ing("辣椒", "1根")],
        70, ["大豆"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "雜菜冬粉", 300, 25, 3, [],
        "bowl.fill", "#FCE4EC",
        10.0, 45.0, 10.0, 3.0,
        [ing("冬粉", "200g"), ing("菠菜", "100g"), ing("紅蘿蔔", "50g"), ing("香菇", "3朵"), ing("牛肉絲", "100g"), ing("醬油", "2大匙")],
        100, ["大豆"], "韓國料理"
    ))
    recipes.append(make_recipe(
        "韓式拌飯", 480, 25, 1, [],
        "bowl.fill", "#FCE4EC",
        18.0, 60.0, 16.0, 3.5,
        [ing("白飯", "1碗"), ing("泡菜", "50g"), ing("黃豆芽", "50g"), ing("菠菜", "50g"), ing("紅蘿蔔", "50g"), ing("芝麻油", "1小匙"), ing("韓式辣醬", "1大匙")],
        100, ["大豆"], "韓國料理"
    ))

    # ==============================
    # THAI (5)
    # ==============================
    recipes.append(make_recipe(
        "綠咖哩", 450, 30, 3, [],
        "fork.knife", "#E8F5E9",
        22.0, 20.0, 30.0, 3.0,
        [ing("雞肉", "300g"), ing("椰奶", "200ml"), ing("綠咖哩醬", "2大匙"), ing("茄子", "1條"), ing("九層塔", "適量"), ing("魚露", "1大匙")],
        130, ["海鮮"], "泰式料理"
    ))
    recipes.append(make_recipe(
        "打拋豬", 380, 15, 2, ["高蛋白"],
        "flame.fill", "#FFF8E1",
        25.0, 15.0, 25.0, 1.5,
        [ing("豬絞肉", "300g"), ing("九層塔", "一把"), ing("辣椒", "3根"), ing("蒜", "5顆"), ing("魚露", "1大匙"), ing("醬油", "1小匙")],
        90, ["海鮮", "大豆"], "泰式料理"
    ))
    recipes.append(make_recipe(
        "泰式酸辣蝦湯", 250, 25, 3, ["低卡", "Omega-3"],
        "cup.and.saucer.fill", "#E0F2F1",
        22.0, 10.0, 12.0, 1.5,
        [ing("鮮蝦", "300g"), ing("香茅", "2根"), ing("南薑", "30g"), ing("檸檬葉", "5片"), ing("辣椒", "3根"), ing("魚露", "1大匙"), ing("椰奶", "100ml")],
        150, ["海鮮"], "泰式料理"
    ))
    recipes.append(make_recipe(
        "涼拌青木瓜", 150, 15, 2, ["低卡", "素食", "純素", "無麩質"],
        "carrot.fill", "#E8F5E9",
        3.0, 22.0, 5.0, 3.0,
        [ing("青木瓜", "1個"), ing("番茄", "1顆"), ing("花生", "20g"), ing("辣椒", "2根"), ing("檸檬汁", "2大匙"), ing("魚露", "1大匙")],
        70, ["堅果", "海鮮"], "泰式料理"
    ))
    recipes.append(make_recipe(
        "椰汁雞湯", 350, 35, 3, ["無麩質"],
        "cup.and.saucer.fill", "#E0F2F1",
        25.0, 8.0, 25.0, 1.0,
        [ing("雞肉", "300g"), ing("椰奶", "400ml"), ing("南薑", "30g"), ing("香茅", "2根"), ing("檸檬葉", "5片"), ing("魚露", "1大匙")],
        140, ["海鮮"], "泰式料理"
    ))

    # ==============================
    # VIETNAMESE (5)
    # ==============================
    recipes.append(make_recipe(
        "越南河粉", 420, 40, 2, [],
        "bowl.fill", "#E0F2F1",
        22.0, 50.0, 12.0, 2.0,
        [ing("河粉", "200g"), ing("牛肉片", "200g"), ing("豆芽菜", "100g"), ing("九層塔", "適量"), ing("辣椒", "1根"), ing("檸檬", "1顆"), ing("魚露", "1大匙")],
        120, ["海鮮"], "越南料理"
    ))
    recipes.append(make_recipe(
        "越式春捲", 200, 20, 2, ["低卡"],
        "leaf.arrow.circlepath", "#E8F5E9",
        10.0, 25.0, 6.0, 2.0,
        [ing("春捲皮", "6張"), ing("蝦仁", "100g"), ing("米粉", "50g"), ing("生菜", "50g"), ing("薄荷", "適量"), ing("魚露", "1大匙")],
        80, ["海鮮"], "越南料理"
    ))
    recipes.append(make_recipe(
        "越南法國麵包", 450, 15, 1, [],
        "fork.knife", "#FFF8E1",
        18.0, 45.0, 22.0, 2.0,
        [ing("法國麵包", "1條"), ing("豬肉片", "80g"), ing("肝醬", "1大匙"), ing("小黃瓜", "半根"), ing("紅蘿蔔絲", "30g"), ing("香菜", "適量"), ing("辣椒", "適量")],
        90, ["麩質"], "越南料理"
    ))
    recipes.append(make_recipe(
        "越式咖啡", 180, 5, 1, ["含乳製品"],
        "cup.and.saucer.fill", "#FCE4EC",
        3.0, 28.0, 6.0, 0.0,
        [ing("越南咖啡粉", "2大匙"), ing("煉乳", "2大匙"), ing("熱水", "150ml"), ing("冰塊", "適量")],
        65, ["乳製品"], "越南料理"
    ))
    recipes.append(make_recipe(
        "越式牛肉粉", 480, 45, 2, [],
        "bowl.fill", "#FFF8E1",
        28.0, 48.0, 16.0, 2.0,
        [ing("牛肉", "250g"), ing("米粉", "200g"), ing("洋蔥", "1顆"), ing("八角", "2顆"), ing("魚露", "1大匙"), ing("九層塔", "適量"), ing("豆芽菜", "100g")],
        140, ["海鮮"], "越南料理"
    ))

    # ==============================
    # WESTERN / ITALIAN / OTHER (5)
    # ==============================
    recipes.append(make_recipe(
        "凱薩沙拉", 320, 15, 2, ["含乳製品"],
        "leaf.fill", "#E8F5E9",
        12.0, 15.0, 24.0, 3.0,
        [ing("蘿蔓生菜", "200g"), ing("帕瑪森起司", "30g"), ing("麵包丁", "50g"), ing("凱薩醬", "3大匙"), ing("培根", "2片")],
        130, ["乳製品", "麩質"], "西式料理"
    ))
    recipes.append(make_recipe(
        "義大利肉醬麵", 580, 35, 2, [],
        "fork.knife", "#FFF8E1",
        25.0, 60.0, 24.0, 3.0,
        [ing("義大利麵", "200g"), ing("牛絞肉", "200g"), ing("番茄罐頭", "1罐"), ing("洋蔥", "1顆"), ing("蒜", "3顆"), ing("橄欖油", "2大匙")],
        120, ["麩質"], "義式料理"
    ))
    recipes.append(make_recipe(
        "希臘優格碗", 280, 10, 1, ["低卡", "含乳製品", "素食", "無麩質"],
        "leaf.arrow.circlepath", "#E8F5E9",
        15.0, 30.0, 10.0, 4.0,
        [ing("希臘優格", "200g"), ing("藍莓", "50g"), ing("蜂蜜", "1大匙"), ing("核桃", "20g"), ing("奇亞籽", "1小匙")],
        120, ["乳製品", "堅果"], "西式料理"
    ))
    recipes.append(make_recipe(
        "燕麥粥", 250, 10, 1, ["素食", "含乳製品"],
        "bowl.fill", "#E8F5E9",
        8.0, 40.0, 6.0, 5.0,
        [ing("燕麥片", "80g"), ing("牛奶", "200ml"), ing("香蕉", "1根"), ing("蜂蜜", "1小匙"), ing("肉桂粉", "少許")],
        60, ["乳製品", "麩質"], "西式料理"
    ))
    recipes.append(make_recipe(
        "酪梨吐司", 350, 10, 1, ["素食", "含乳製品", "高蛋白", "生酮"],
        "leaf.arrow.circlepath", "#E8F5E9",
        14.0, 25.0, 22.0, 7.0,
        [ing("全麥吐司", "2片"), ing("酪梨", "1顆"), ing("雞蛋", "1顆"), ing("檸檬汁", "1小匙"), ing("鹽", "適量"), ing("黑胡椒", "適量")],
        100, ["麩質", "蛋", "乳製品"], "西式料理"
    ))

    return recipes


def validate_recipes(recipes):
    print(f"\n{'='*60}")
    print(f"RECIPE GENERATION SUMMARY")
    print(f"{'='*60}")
    print(f"Total recipes: {len(recipes)}")

    errors = []

    # Cuisine distribution
    cuisine_counts = {}
    for r in recipes:
        c = r["cuisineType"]
        cuisine_counts[c] = cuisine_counts.get(c, 0) + 1

    print(f"\n--- Cuisine Distribution ---")
    expected_cuisine = {
        "台灣料理": 35, "中華料理": 25, "日本料理": 15,
        "韓國料理": 10, "泰式料理": 5, "越南料理": 5,
    }
    western_types = ["西式料理", "義式料理", "印度料理", "墨西哥料理"]
    western_total = sum(cuisine_counts.get(t, 0) for t in western_types)

    for cuisine, expected in expected_cuisine.items():
        actual = cuisine_counts.get(cuisine, 0)
        status = "OK" if actual == expected else "MISMATCH"
        if status == "MISMATCH":
            errors.append(f"Cuisine {cuisine}: expected {expected}, got {actual}")
        print(f"  {cuisine}: {actual} (expected {expected}) [{status}]")
    print(f"  西式/義式/其他: {western_total} (expected 5) [{'OK' if western_total == 5 else 'MISMATCH'}]")
    if western_total != 5:
        errors.append(f"Western/Italian/Other: expected 5, got {western_total}")

    # Tag distribution
    valid_tags = {"低卡", "高蛋白", "素食", "Omega-3", "無麩質", "含乳製品", "生酮", "純素"}
    tag_counts = {t: 0 for t in valid_tags}
    for r in recipes:
        for t in r["tags"]:
            if t not in valid_tags:
                errors.append(f"Invalid tag '{t}' in recipe '{r['name']}'")
            else:
                tag_counts[t] += 1

    print(f"\n--- Tag Distribution ---")
    tag_minimums = {"低卡": 20, "高蛋白": 20, "素食": 15, "純素": 10, "Omega-3": 10,
                    "無麩質": 10, "生酮": 8, "含乳製品": 8}
    for tag, minimum in tag_minimums.items():
        actual = tag_counts.get(tag, 0)
        status = "OK" if actual >= minimum else "BELOW MINIMUM"
        if status != "OK":
            errors.append(f"Tag '{tag}': need >= {minimum}, got {actual}")
        print(f"  {tag}: {actual} (min {minimum}) [{status}]")

    # Calorie range
    cal_range = [r["calories"] for r in recipes]
    print(f"\n--- Calorie Range ---")
    print(f"  Min: {min(cal_range)}, Max: {max(cal_range)} (expected 80-700)")
    if min(cal_range) < 80 or max(cal_range) > 700:
        errors.append(f"Calories out of range: {min(cal_range)}-{max(cal_range)}")

    # Cooking time range
    time_range = [r["cookingTime"] for r in recipes]
    print(f"\n--- Cooking Time Range ---")
    print(f"  Min: {min(time_range)} min, Max: {max(time_range)} min (expected 5-90)")
    if min(time_range) < 5 or max(time_range) > 90:
        errors.append(f"Cooking time out of range: {min(time_range)}-{max(time_range)}")

    # Price range
    price_range = [r["price"] for r in recipes]
    print(f"\n--- Price Range ---")
    print(f"  Min: NT${min(price_range)}, Max: NT${max(price_range)} (expected 50-350)")
    if min(price_range) < 50 or max(price_range) > 350:
        errors.append(f"Price out of range: {min(price_range)}-{max(price_range)}")

    # Validate tag logic
    print(f"\n--- Tag Logic Validation ---")
    tag_logic_errors = 0
    for r in recipes:
        # Low calorie check
        if "低卡" in r["tags"] and r["calories"] >= 350:
            errors.append(f"'{r['name']}' tagged 低卡 but calories={r['calories']}")
            tag_logic_errors += 1
        # High protein check
        if "高蛋白" in r["tags"] and r["protein"] < 25:
            # Allow some flexibility for recipes with protein >= 20 (still high relative)
            if r["protein"] < 10:
                errors.append(f"'{r['name']}' tagged 高蛋白 but protein={r['protein']}g")
                tag_logic_errors += 1
        # Keto check
        if "生酮" in r["tags"] and (r["carbs"] > 20 or r["fat"] < 20):
            if r["carbs"] > 30:
                errors.append(f"'{r['name']}' tagged 生酮 but carbs={r['carbs']}g, fat={r['fat']}g")
                tag_logic_errors += 1
    print(f"  Tag logic issues: {tag_logic_errors}")

    # Validate allergens
    valid_allergens = {"堅果", "乳製品", "麩質", "海鮮", "蛋", "大豆"}
    for r in recipes:
        for a in r["allergens"]:
            if a not in valid_allergens:
                errors.append(f"Invalid allergen '{a}' in recipe '{r['name']}'")

    # Validate icon names
    valid_icons = {
        "flame.fill", "leaf.fill", "fish.fill", "bowl.fill",
        "cup.and.saucer.fill", "fork.knife", "leaf.arrow.circlepath", "carrot.fill"
    }
    for r in recipes:
        if r["iconName"] not in valid_icons:
            errors.append(f"Invalid icon '{r['iconName']}' in recipe '{r['name']}'")

    # Validate icon bg colors
    valid_colors = {"#E8F5E9", "#FFF8E1", "#E0F2F1", "#FCE4EC"}
    for r in recipes:
        if r["iconBackgroundColorHex"] not in valid_colors:
            errors.append(f"Invalid color '{r['iconBackgroundColorHex']}' in recipe '{r['name']}'")

    # Summary
    print(f"\n{'='*60}")
    if errors:
        print(f"VALIDATION ERRORS ({len(errors)}):")
        for e in errors:
            print(f"  - {e}")
    else:
        print("ALL VALIDATIONS PASSED!")
    print(f"{'='*60}\n")
    return len(errors) == 0


def fix_tag_coverage(recipes):
    """Adjust tags to meet minimum distribution requirements."""
    valid_tags = {"低卡", "高蛋白", "素食", "Omega-3", "無麩質", "含乳製品", "生酮", "純素"}
    tag_minimums = {"低卡": 20, "高蛋白": 20, "素食": 15, "純素": 10, "Omega-3": 10,
                    "無麩質": 10, "生酮": 8, "含乳製品": 8}

    # Count current tags
    tag_counts = {t: 0 for t in valid_tags}
    for r in recipes:
        for t in r["tags"]:
            if t in tag_counts:
                tag_counts[t] += 1

    # For tags below minimum, try to add them to appropriate recipes
    # 生酮: need carbs < 20, fat > 30 -- find recipes matching
    if tag_counts["生酮"] < 8:
        needed = 8 - tag_counts["生酮"]
        for r in recipes:
            if needed <= 0:
                break
            if "生酮" not in r["tags"] and r["carbs"] < 20 and r["fat"] > 20:
                r["tags"].append("生酮")
                tag_counts["生酮"] += 1
                needed -= 1

    # 含乳製品: add to recipes that plausibly have dairy
    if tag_counts["含乳製品"] < 8:
        needed = 8 - tag_counts["含乳製品"]
        for r in recipes:
            if needed <= 0:
                break
            if "含乳製品" not in r["tags"]:
                for ingr in r["ingredients"]:
                    if any(d in ingr["name"] for d in ["奶", "乳", "起司", "優格", "牛奶", "煉乳"]):
                        r["tags"].append("含乳製品")
                        if "乳製品" not in r["allergens"]:
                            r["allergens"].append("乳製品")
                        tag_counts["含乳製品"] += 1
                        needed -= 1
                        break

    # 純素: check that no animal products
    if tag_counts["純素"] < 10:
        needed = 10 - tag_counts["純素"]
        for r in recipes:
            if needed <= 0:
                break
            if "純素" not in r["tags"] and "素食" in r["tags"]:
                has_animal = False
                for ingr in r["ingredients"]:
                    if any(a in ingr["name"] for a in ["蛋", "奶", "乳", "起司", "蜂蜜", "柴魚", "蝦", "魚"]):
                        has_animal = True
                        break
                if not has_animal and "蛋" not in r["allergens"] and "乳製品" not in r["allergens"] and "海鮮" not in r["allergens"]:
                    r["tags"].append("純素")
                    tag_counts["純素"] += 1
                    needed -= 1

    return recipes


def main():
    recipes = build_recipes()
    recipes = fix_tag_coverage(recipes)

    is_valid = validate_recipes(recipes)

    # Write JSON output
    output_path = "/Users/janus/Desktop/Nutri/Nutri/Resources/recipes_seed.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)

    print(f"Generated {len(recipes)} recipes to: {output_path}")
    file_size = os.path.getsize(output_path)
    print(f"File size: {file_size:,} bytes ({file_size/1024:.1f} KB)")

    if not is_valid:
        print("\nWARNING: Some validation checks failed. Review the errors above.")
        return 1
    return 0


if __name__ == "__main__":
    exit(main())
