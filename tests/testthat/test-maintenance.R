test_that("names_list accepts omitted and compatibility arguments", {
  without_argument <- names_list()
  with_argument <- names_list("compatibility value")

  expect_type(without_argument, "character")
  expect_identical(with_argument, without_argument)
})

test_that("make_ntspmat honors the supplied year column name", {
  data_year <- data.frame(
    country = factor(rep(c(
      "United Kingdom", "Ireland", "Netherlands",
      "Belgium", "France", "Spain"
    ), each = 2)),
    year = rep(c(2018, 2019), 6),
    y = seq_len(12),
    x = rep(c(0, 1), 6)
  )
  data_period <- data_year
  names(data_period)[names(data_period) == "year"] <- "period"

  assign("maintenance_data_year", data_year, envir = .GlobalEnv)
  assign("maintenance_data_period", data_period, envir = .GlobalEnv)
  on.exit(
    rm(list = c("maintenance_data_year", "maintenance_data_period"), envir = .GlobalEnv),
    add = TRUE
  )

  model_year <- lm(y ~ x, data = maintenance_data_year)
  model_period <- lm(y ~ x, data = maintenance_data_period)

  weights_year <- make_ntspmat(model_year, country, year, 3)
  weights_period <- make_ntspmat(model_period, country, period, 3)

  expect_length(weights_year, 4)
  expect_length(weights_period, 4)
  expect_null(names(weights_year))
  expect_null(names(weights_period))
  expect_identical(weights_year[[2]], weights_period[[2]])
  expect_identical(as.character(weights_year[[3]]), "country")
  expect_identical(as.character(weights_year[[4]]), "year")
  expect_identical(as.character(weights_period[[3]]), "country")
  expect_identical(as.character(weights_period[[4]]), "period")
  expect_identical(weights_year[[1]]$coln, weights_period[[1]]$coln)
})

test_that("st_effects uses stored year metadata and returns numeric sizes", {
  panel <- data.frame(
    unit = rep(c("A", "B"), 2),
    period = rep(c(1, 2), each = 2),
    outcome = c(1, 2, 3, 4)
  )
  weights_matrix <- matrix(c(
    0, 1, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 1,
    0, 0, 1, 0
  ), nrow = 4, byrow = TRUE)
  weights <- list(panel, weights_matrix, "unit", "period")
  model <- structure(
    list(coefficients = c(tlag = 0.2, covariate = 0.5)),
    class = "maintenance_spatial_model"
  )
  assign(
    "summary.maintenance_spatial_model",
    function(object, ...) list(rho = 0.1),
    envir = .GlobalEnv
  )
  on.exit(rm("summary.maintenance_spatial_model", envir = .GlobalEnv), add = TRUE)

  effects <- st_effects(model, weights, tlag, covariate)

  expect_identical(
    effects$Effect,
    c("Direct Short-Run:", "Indirect Short-Run:", "Total Short-Run:",
      "Direct Long-Run:", "Indirect Long-Run:", "Total Long-Run:")
  )
  expect_type(effects$Size, "double")
  expect_equal(
    effects$Size,
    c(0.505, 0.051, 0.556, 0.631, 0.063, 0.694)
  )
  expect_named(effects, c("Effect", "Size"))
  expect_equal(nrow(effects), 6)
})
