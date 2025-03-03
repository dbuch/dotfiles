---@class CargoArgs
---@field workspaceRoot string|nil
---@field cargoArgs string[]
---@field cargoExtraArgs string[]
---@field expectTest boolean|nil
---@field overrideCargo string|nil

---@class Runnable
---@field label string
---@field kind string
---@field args CargoArgs
---@field location any

---@class RunnableJobArgs
---@field command string
---@field cwd string
---@field args string[]

---@class ResponseError
---@field code integer
---@field message string
---@field data string | number | boolean | Array | Object | nil;

---@class CargoMetadata
---@field packages CargoPackages[]
---@field workspace_members string[]
---@field resolve CargoResolve[]|nil
---@field target_directory string
---@field version integer
---@field workspace_root string
---@field metadata table --TODO Define type if posible

---@class CargoPackages
---@field name string
---@field version string
---@field id string
---@field license string|nil
---@field license_file string|nil
---@field description string|nil
---@field source string|nil
---@field dependencies CargoPackageDeps[]
---@field targets CargoPackageTargets[]
---@field features table<string, string[]>
---@field manifest_path string
---@field metadata table --TODO Define type
---@field publish string[]|nil
---@field authors string[]
---@field categories string[]
---@field default_run string|nil
---@field rust_version string
---@field keywords string[]
---@field readme string|nil
---@field repository string|nil
---@field homepage string|nil
---@field documentation string|nil
---@field edition string|nil
---@field links string|nil

---@class CargoPackageDeps
---@field name string
---@field source string|nil
---@field req string
---@field kind string --TODO Could be an enum?
---@field rename string|nil
---@field optional boolean
---@field uses_default_features boolean
---@field features string[]
---@field target string|nil
---@field path string|nil
---@field registry string|nil

---@class CargoPackageTargets
---@field kind string[]
---@field crate_types string[]
---@field name string
---@field src_path string
---@field edition string
---@field required_features string[]|nil
---@field doc boolean
---@field doctest boolean
---@field test boolean

---@class CargoResolve
---@field nodes CargoResolveNode[]
---@field root string|nil

---@class CargoResolveNodeDepKind
---@field kind string|nil
---@field target string|nil

---@class CargoResolveNodeDeps
---@field name string
---@field pkg string
---@field dep_kinds CargoResolveNodeDepKind[]

---@class CargoResolveNode
---@field id string
---@field dependencies string[]
---@field deps CargoResolveNode[]
