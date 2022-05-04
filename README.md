Agent-Based Model developped in the [CityScience](https://www.media.mit.edu/groups/city-science/overview/) group using [Gama Platform](https://gama-platform.github.io/).

# Installation
  - Clone this repository
  - Download GAMA [here](https://gama-platform.github.io/download)
  - Run GAMA
  - Choose a new Workspace (this is a temporay folder used for computation)
  - Right click on User Models->Import->GAMA Project.. and import the project that you just cloned

# Overall Structure:
- The `parameters.gaml` file specificies universal constants and simulation parameters
- The `Agents.gaml` file specifies simulation species and their behaviors.
- The `clustering.gaml` file specifies the initialization state, as well as the different experiments to be run and a few global functions
