"""
The constant LAND_MASK is a filepath to a NCDataset whose dimensions are latitude and
longitude and data are 1s and 0s. The 1s indicate land and 0s indicate ocean.
"""
LAND_MASK = joinpath(@__DIR__, "..", "masks", "land_mask4.nc")

"""
The constant LAND_MASK is a filepath to a NCDataset whose dimensions are latitude and
longitude and data are 1s and 0s. The 1s indicate ocean and 0s indicate land.
"""
OCEAN_MASK = joinpath(@__DIR__, "..", "masks", "ocean_mask4.nc")
