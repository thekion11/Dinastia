#ifndef _HPP_MATERIAL
#define _HPP_MATERIAL

#include "scene/resources/surface.hpp"

namespace blunted {

struct Material {
  boost::intrusive_ptr<Resource<Surface>> diffuseTexture;
  boost::intrusive_ptr<Resource<Surface>> normalTexture;
  boost::intrusive_ptr<Resource<Surface>> specularTexture;
  boost::intrusive_ptr<Resource<Surface>> illuminationTexture;
  float shininess;
  float specular_amount;
  Vector3 self_illumination;
  Material() = default;
  Material(const Material&) = default;
  Material& operator=(const Material&) = default;
  Material(Material&&) noexcept = default;
  Material& operator=(Material&&) noexcept = default;
};

}  // namespace blunted

#endif
