from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Variant:
    key: str
    name: str
    family: str
    plot_kind: str
    param_labels: tuple[str, ...] = ()
    param_defaults: tuple[str, ...] = ()
    aliases: tuple[str, ...] = ()

    @property
    def default_tuple(self) -> str:
        """Return the MATLAB tuple-editor default for this variant."""
        return ",".join(self.param_defaults)


@dataclass(frozen=True)
class Family:
    key: str
    name: str
    default_xrange: tuple[float, float]
    variants: tuple[Variant, ...]


FAMILIES: tuple[Family, ...] = (
    Family("bessel", "Bessel", (0.0, 20.0), (
        Variant("j", "Bessel J", "bessel", "1d", ("nu",), ("0:5",)),
        Variant("y", "Bessel Y", "bessel", "1d", ("nu",), ("0:5",)),
        Variant("i", "Modified Bessel I", "bessel", "1d", ("nu",), ("0:5",)),
        Variant("k", "Modified Bessel K", "bessel", "1d", ("nu",), ("0:5",)),
    )),
    Family("spherical_bessel", "Spherical Bessel", (0.05, 20.0), (
        Variant("spherical_j", "Spherical Bessel j", "spherical_bessel", "1d", ("n",), ("0:5",), ("j",)),
        Variant("spherical_y", "Spherical Bessel y", "spherical_bessel", "1d", ("n",), ("0:5",), ("y",)),
    )),
    Family("airy", "Airy", (-10.0, 5.0), (
        Variant("ai", "Airy Ai", "airy", "1d"),
        Variant("bi", "Airy Bi", "airy", "1d"),
        Variant("aip", "Airy Ai derivative", "airy", "1d"),
        Variant("bip", "Airy Bi derivative", "airy", "1d"),
    )),
    Family("lane_emden", "Lane-Emden", (0.0, 10.0), (
        Variant("lane_emden", "Lane-Emden theta", "lane_emden", "1d", ("n",), ("0,1,1.5,3,5",), ("theta",)),
    )),
    Family("elliptic", "Elliptic Integrals", (0.0, 0.999), (
        Variant("ellipk", "Complete elliptic K", "elliptic", "1d", aliases=("k",)),
        Variant("ellipe", "Complete elliptic E", "elliptic", "1d", aliases=("e",)),
        Variant("ellipf_inc", "Incomplete elliptic F", "elliptic", "1d", ("m",), ("0.5",), ("f_inc",)),
        Variant("ellipe_inc", "Incomplete elliptic E", "elliptic", "1d", ("m",), ("0.5",), ("e_inc",)),
        Variant("ellippi_inc", "Incomplete elliptic Pi", "elliptic", "1d", ("n", "m"), ("0.2", "0.5"), ("pi_inc",)),
    )),
    Family("jacobi_elliptic", "Jacobi Elliptic", (0.0, 12.0), (
        Variant("sn", "Jacobi sn", "jacobi_elliptic", "1d", ("m",), ("0,0.5,0.95",)),
        Variant("cn", "Jacobi cn", "jacobi_elliptic", "1d", ("m",), ("0,0.5,0.95",)),
        Variant("dn", "Jacobi dn", "jacobi_elliptic", "1d", ("m",), ("0,0.5,0.95",)),
    )),
    Family("hypergeometric", "Hypergeometric", (-0.9, 0.9), (
        Variant("hyp2f1", "Gauss 2F1", "hypergeometric", "1d", ("a", "b", "c"), ("0.5", "1", "2"), ("2f1",)),
    )),
    Family("spherical_harmonics", "Spherical Harmonics", (0.0, 1.0), (
        Variant("ylm", "Spherical harmonic Y", "spherical_harmonics", "3d", ("l", "m"), ("0:3", "-3:3"), ("spherical harmonic",)),
    )),
    Family("vector_spherical_harmonics", "Vector Spherical Harmonics", (0.0, 1.0), (
        Variant("xlm", "Toroidal X", "vector_spherical_harmonics", "3d", ("l", "m"), ("0:3", "-3:3"), ("vector spherical harmonic",)),
        Variant("psilm", "Surface-gradient Psi", "vector_spherical_harmonics", "3d", ("l", "m"), ("0:3", "-3:3")),
        Variant("radial", "Radial rhat Y", "vector_spherical_harmonics", "3d", ("l", "m"), ("0:3", "-3:3")),
    )),
)

ALIASES = {
    "bessel": "bessel",
    "spherical bessel": "spherical_bessel",
    "airy": "airy",
    "lane-emden": "lane_emden",
    "lane emden": "lane_emden",
    "elliptic integrals": "elliptic",
    "jacobi elliptic": "jacobi_elliptic",
    "hypergeometric": "hypergeometric",
    "spherical harmonics": "spherical_harmonics",
    "vector spherical harmonics": "vector_spherical_harmonics",
    "bessel j": "j",
    "bessel y": "y",
    "bessel i": "i",
    "bessel k": "k",
    "modified bessel i": "i",
    "modified bessel k": "k",
    "airy ai": "ai",
    "airy bi": "bi",
    "spherical harmonic": "ylm",
    "vector spherical harmonic": "xlm",
    "gauss 2f1": "hyp2f1",
}


def normalize_key(value: str) -> str:
    key = str(value).strip().lower().replace("_", " ").replace("-", " ")
    key = " ".join(key.split())
    return ALIASES.get(key, key.replace(" ", "_"))


def get_family(selector: str | None) -> Family:
    key = normalize_key(selector or "bessel")
    for family in FAMILIES:
        if family.key == key or normalize_key(family.name) == key:
            return family
    return FAMILIES[0]


def get_variant(family_selector: str | None, variant_selector: str | None) -> Variant:
    family = get_family(family_selector)
    key = normalize_key(variant_selector or family.variants[0].key)
    for variant in family.variants:
        if _matches_variant(variant, key):
            return variant
    for other_family in FAMILIES:
        for variant in other_family.variants:
            if _matches_variant(variant, key):
                return variant if variant.family == family.key else family.variants[0]
    return family.variants[0]


def _matches_variant(variant: Variant, key: str) -> bool:
    return key == variant.key or key == normalize_key(variant.name) or any(
        key == normalize_key(alias) for alias in variant.aliases
    )
