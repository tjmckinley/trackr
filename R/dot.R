
#' Convert dot to svg
#'
#' Convert a digraph as string to SVG as string
#'
#' @param dot - a graphviz dot string
#'
#' @return the SVG as a string
#' @export
#'
#' @examples dot2svg("digraph {A->B}")
dot2svg <- function(dot) {

  if(!requireNamespace("V8", quietly = TRUE)) stop("V8 package is required", call. = FALSE)
  if (!(utils::packageVersion("V8") >= "1.0")) {
    stop('your "V8" package is too old. The DOT package requires V8
        package version 1.0 or newer', call. = FALSE)
  }
  # remove the "\n" from DOT source

  scriptDOT <- gsub("[\r\n]", " ", dot)
  scriptDOT <- gsub("'", "\"", scriptDOT)
  dot <- paste("'", scriptDOT, "'", sep="")

  JS <- system.file("lib/viz.js", package = "trackr")
  # this is an old vis.js
  # newer versions are here https://github.com/aduh95/viz.js but use npm and assume node.

  ENV <- V8::v8();
  ENV$source(JS)
  call <- paste("image = Viz(", dot, ")", sep = "")
  content <- ENV$eval(call)
  return(content)

  # viewer <- getOption("viewer")
  # if (!is.null(viewer) & display) {
  #   viewer(dotFile)
  # }

}

#' Standard paper sizes
#'
#' @export
std_size = list(
  A4 = list(width=8.25,height=11.75,rot=0),
  A5 = list(width=5+7/8,height=8.25,rot=0),
  full =  list(width=5.9,height=8,rot=0),
  half =  list(width=5.9,height=4,rot=0),
  third =  list(width=5.9,height=3,rot=0),
  two_third = list(width=5.9,height=6,rot=0),
  quarter = list(width=5.9,height=2,rot=0),
  sixth = list(width=3,height=3,rot=0)
)

#' Convert page size from portrait to landscape
#'
#' @param size - list of width and height in inches, e.g. a std_size
#'
#' @return a landscape size
#' @export
landscape = function(size) {return(list(width=size$height, height = size$width, rot=270))}


.relPath = function(pathname) {
  # Split the two pathnames into their components
  relativeTo <- unlist(strsplit(getwd(), split="[\\/]"))
  pathname <- unlist(strsplit(pathname, split="[\\/]"))
  pathnameC <- pathname

  # 1. Check that the pathnames are "compatible".
  if (!identical(relativeTo[1L], pathnameC[1L])) {
    pathname <- paste(pathname, collapse="/")
    # warning("Cannot infer relative pathname, because the two pathnames are not refering to the same root/device (will use absolute pathname instead): ", paste(relativeTo, collapse="/"), " != ", pathname)
    return(pathname)
  }

  # 2. Remove all matching components in 'relativeTo' and 'pathname'.
  #    The removed parts constitute their common path.
  for (kk in seq_along(relativeTo)) {
    aPart <- relativeTo[1]
    bPart <- pathnameC[1]
    if (!identical(aPart, bPart))
      break

    relativeTo <- relativeTo[-1L]
    pathname <- pathname[-1L]
    pathnameC <- pathnameC[-1L]
  }

  # 3. If there are more components in 'relativeTo', this means that the
  #    rest of 'relativeTo' is in a different subdirectory than 'pathname'.
  prefix <- rep("..", length.out=length(relativeTo))

  pathname <- c(prefix, pathname)
  pathname <- paste(pathname, collapse="/")

  if (pathname == "")
    pathname <- "."

  pathname
}

#' Save DOT to a file
#'
#' Convert a digraph and save as a file
#'
#' @param dot - a graphviz dot string
#' @param filename - the root of the desired filename (minus extension)
#' @param size - a list of length and width in inches e.g. a std_size
#' @param maxWidth - a width in inches is size is not defined
#' @param maxHeight - a heught in inches if size is not defined
#' @param rot - an angle of rotation for the saved file if size is not defined
#' @param formats - some of "pdf","dot","svg","png","ps"
#'
#' @return the SVG as a string
#' @export
#'
#' @examples dot2svg("digraph {A->B}")
save_dot = function(dot,filename,size = std_size$half, maxWidth = size$width, maxHeight = size$height, rot=size$rot, formats=c("dot","png","pdf","svg")) {

  # warning("params: ",maxWidth,"x",maxHeight,"; rot: ",rot)

  fname = function(extn) normalizePath(paste0(filename,".",extn),mustWork = FALSE)




  if ("dot" %in% formats) {
    # message("saving dot to: ",fname("dot"))
    suppressMessages(unlink(fname("dot")))
    dot %>% writeChar(fname("dot"))
  }

  svg = dot %>% dot2svg()
  defaultWidth = (svg %>% stringr::str_match("width=\"([0-9]*)pt\""))[1,2] %>% as.numeric()
  defaultHeight = (svg %>% stringr::str_match("height=\"([0-9]*)pt\""))[1,2] %>% as.numeric()

  # warning("default size: ",defaultWidth,"x",defaultHeight)

  aspectRatio = defaultWidth / defaultHeight

  if ("pdf" %in% formats) {
    svg %>% charToRaw() %>% rsvg::rsvg_pdf(
      file = fname("pdf"),
      width = min(maxWidth,maxHeight*aspectRatio,defaultWidth)*72,
      height = min(maxHeight,maxWidth/aspectRatio,defaultHeight)*72
    )
    try(
      grDevices::embedFonts(fname("pdf")),
      silent=TRUE
    );
    if (rot!=0 & isNamespaceLoaded("staplr")) {
      staplr::rotate_pdf(page_rotation = rot,
        input_filepath = fname("pdf"),
        output_filepath = fname("pdf"),
        overwrite = TRUE)
    }
  }

  if ("png" %in% formats) {
    svg %>% charToRaw() %>% rsvg::rsvg_png(
      file = fname("png"),
      width = min(maxWidth,maxHeight*aspectRatio,defaultWidth)*300,
      height = min(maxHeight,maxWidth/aspectRatio,defaultHeight)*300
    )
    if (rot != 0 & isNamespaceLoaded("magick")) {
      magick::image_rotate(
        magick::image_read(
          fname("png")
        )
        ,rot
      ) %>% magick::image_write(
        fname("png")
      )
    }
  }

  if ("svg" %in% formats) {
    svg %>% charToRaw() %>% rsvg::rsvg_svg(
      file = fname("svg"),
      width = min(maxWidth,maxHeight*aspectRatio,defaultWidth)*72,
      height = min(maxHeight,maxWidth/aspectRatio,defaultHeight)*72
    )
  }

  if ("ps" %in% formats) {
    svg %>% charToRaw() %>% rsvg::rsvg_ps(
        file = fname("ps"),
        width = min(maxWidth,maxHeight*aspectRatio,defaultWidth)*72,
        height = min(maxHeight,maxWidth/aspectRatio,defaultHeight)*72
    )
  }

  if (isTRUE(getOption("knitr.in.progress"))) {
    fmt <- rmarkdown::default_output_format(knitr::current_input())$name
    if (fmt %>% stringr::str_detect("html") || fmt=="article") {
      return(htmltools::HTML(svg))
    } else {
      return(knitr::include_graphics(path = .relPath(fname("png")),auto_pdf = TRUE))
    }
  } else {
    return(htmltools::HTML(svg))
  }

}



