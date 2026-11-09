
<div align="center">
  
# E. Bonus Questions

</div>

**If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?**

- Use INSERT into `pizza_recipes` to add a new `pizza_id` with its toppings stored as a comma-separated string, matching the existing format
- Use INSERT into `pizza_names` to give the new `pizza_id` a name, so it shows up in joins with the other tables

```SQL
INSERT INTO pizza_recipes (pizza_id, toppings) 
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

SELECT pn.pizza_id, pn.pizza_name, pr.toppings FROM pizza_names pn 
INNER JOIN pizza_recipes pr 
    ON pn.pizza_id = pr.pizza_id;
```
**Result:**

<img width="437" height="152" alt="1" src="https://github.com/user-attachments/assets/3b0828f2-a4a7-4b49-8f25-26432e45df1a" /><br>
<img width="295" height="156" alt="2" src="https://github.com/user-attachments/assets/fe0c6fdc-bfaa-41ca-94e8-ccd1c2320aae" /><br>
<img width="573" height="152" alt="3" src="https://github.com/user-attachments/assets/a3a815bd-8948-4139-bf8e-2569c34241f6" /><br>

- Adding a new pizza called `Supreme` wouldn't change the data design dramatically. Rather we would be adding an additional `pizza_id` (id = 3) across the following tables `pizza_recipes` that shows all the ingredients used and `pizza_name` that assigns a name to the `pizza_id`. 
