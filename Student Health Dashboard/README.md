# 🎓 Student Health Dashboard

## Objective
I explored the College Student Health Behavior Dataset to see how lifestyle and psychological factors (stress, sleep, physical activity, academic pressure) differ among students classified as fit, at-risk, and unhealthy.

## Data
- **Source:** [College Student Health Behavior Dataset](https://www.kaggle.com/datasets/ziya07/college-student-health-behavior-dataset)
- **Code:** Not available, see dashboard

- **Tools:** PostgreSQL, Tableau
- **Skills:** Data analyzing, data visualization

## Approach
1. **Scan and upload data:** Reviewed the dataset's structure and columns, then loaded it into PostgreSQL.
2. **Analyze data:** Queried the data in PostgreSQL to summarize stress, sleep, physical activity, mental health, and academic pressure across the fit, at-risk, and unhealthy groups.
3. **Built a dashboard:** Created an interactive Tableau dashboard comparing the three groups.

## Findings
- Fit students made up 50.96% of the dataset, at-risk students 43.08%, and unhealthy students 5.96%.
- Fit students mostly reported low to medium stress and moderate to high physical activity. Unhealthy students mostly reported high stress and sedentary habits.
- Students sleeping 7+ hours tended to report lower stress and academic pressure than those sleeping under 7 hours.
- Unhealthy students had the poorest mental health but still reported high academic performance. This could point to academic pressure, but the dashboard doesn't test that.

<img src="Overview.png" alt="Dashboard Image" width=800>

Dashboard: [College Student Health Dashboard](https://public.tableau.com/app/profile/ren.alcalde/viz/CollegeStudentHealthDashboard/Overview)

## Results
The dashboard suggests a possible relationship between higher stress and academic pressure for students with poorer health classifications, while better sleep and more activity go together with fitter ones. These are descriptive patterns, not tested relationships, and the counts may be affected by repeated records (see below).

## Future Improvements
- The dataset includes repeated records for some students, which I did not remove, so the group percentages may be overstated or skewed.
- The dashboard shows patterns but no statistics, so I can't say whether differences between groups are significant.
- Next: deduplicate the data in PostgreSQL, recalculate the figures, and add labels and summary statistics to the dashboard.
