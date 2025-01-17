WITH_DIMENSION_EXTENSION <- "OSPSuite.Core.Domain.WithDimensionExtensions"
WITH_DISPLAY_UNIT_EXTENSION <- "OSPSuite.Core.Domain.WithDisplayUnitExtensions"

#' @title DataColumn
#' @docType class
#' @description  One column defined in a `DataRepository`
#' @format NULL
DataColumn <- R6::R6Class(
  "DataColumn",
  inherit = DotNetWrapper,
  cloneable = FALSE,
  active = list(
    #' @field values Returns the values defined in the column
    values = function(value) {
      private$wrapVectorProperty("Value", "ValuesAsArray", value, "ValuesAsArray")
    },
    #' @field name Returns the name of the column  (Read-Only)
    name = function(value) {
      private$wrapReadOnlyProperty("Name", value)
    },
    #' @field unit The base unit in which the values are defined (Read-Only)
    unit = function(value) {
      if (!missing(value)) {
        value <- enc2utf8(value)
      }
      private$.unit <- private$wrapExtensionMethodCached(WITH_DIMENSION_EXTENSION, "BaseUnitName", "unit", private$.unit, value)
      return(private$.unit)
    },
    #' @field displayUnit The unit in which the values should be displayed
    displayUnit = function(value) {
      if (missing(value)) {
        return(private$wrapExtensionMethod(WITH_DISPLAY_UNIT_EXTENSION, "DisplayUnitName", "displayUnit", value))
      }
      value <- enc2utf8(value)
      dimension <- getDimensionByName(self$dimension)
      # we use the ignore case parameter set  to true so that we do not have to worry about casing when set via scripts
      unit <- rClr::clrCall(dimension, "FindUnit", value, TRUE)
      if (is.null(unit)) {
        stop(messages$errorUnitNotSupported(unit = value, dimension = self$dimension))
      }
      rClr::clrSet(self$ref, "DisplayUnit", unit)
    },
    #' @field dimension The dimension of the values
    dimension = function(value) {
      if (missing(value)) {
        if (is.null(private$.dimension)) {
          private$.dimension <- private$wrapExtensionMethodCached(WITH_DIMENSION_EXTENSION, "DimensionName", "dimension", private$.dimension, value)
        }
        return(private$.dimension)
      }
      value <- enc2utf8(value)
      # updating the dimension
      rClr::clrSet(self$ref, "Dimension", getDimensionByName(value))
      private$.dimension <- NULL
      private$.unit <- NULL
    },
    #' @field molWeight Molecular weight of associated observed data in internal unit
    #' In no molecular weight is defined, the value is `NULL`
    molWeight = function(value) {
      dataInfo <- rClr::clrGet(self$ref, "DataInfo")
      if (missing(value)) {
        return(rClr::clrGet(dataInfo, "MolWeight"))
      }

      validateIsNumeric(value)
      rClr::clrSet(dataInfo, "MolWeight", value)
    },
    #' @field LLOQ Lower Limit Of Quantification.
    #' In no LLOQ is defined, the value is `NULL`
    LLOQ = function(value) {
      dataInfo <- rClr::clrGet(self$ref, "DataInfo")
      if (missing(value)) {
        return(rClr::clrGet(dataInfo, "LLOQAsDouble"))
      }

      validateIsNumeric(value)
      rClr::clrSet(dataInfo, "LLOQAsDouble", value)
    }
  ),
  public = list(
    #' @description
    #' Print the object to the console
    #' @param ... Rest arguments.
    print = function(...) {
      if (self$unit == "") {
        private$printLine(self$name)
      } else {
        private$printLine(self$name, paste0("base unit: [", self$unit, "]"))
      }
      invisible(self)
    }
  ),
  private = list(
    .unit = NULL,
    .dimension = NULL
  )
)
