#include "ParticleSystem.h"
#include "ParticleMemory.h"

#include "tinyxml2.h"
#include <string>
#define GET_F(map, name) atof((map)[name].c_str())
#define GET_I(map, name) atoi((map)[name].c_str())

namespace Simple2D
{
	ParticleSystem::ParticleSystem()
	{
		pEmitter = new ParticleEmitter();
	}

	ParticleSystem::~ParticleSystem()
	{
		delete pEmitter;
	}

	void ParticleSystem::setTexture(const char* filename)
	{
        texture = TextureManager::instance()->getTexture(filename);
	}

	void ParticleSystem::initWithPlist(const char* filename)
	{
        ParticleConfigMap map = this->parseParticlePlistFile(filename);
        ParticleDescription desc = this->createParticleDescription(map);
        this->setDescription(desc);
	}

	void ParticleSystem::setDescription(const ParticleDescription& desc)
	{
		pEmitter->setDecription(desc);
	}

	void ParticleSystem::update(float dt)
	{
		pEmitter->update(dt);
	}

	RenderUnit ParticleSystem::render()
	{
		float s = 0, c = 0, x = 0, y = 0;

		auto particleIndex = pEmitter->getParticleList();
		Particle* particle = nullptr;

		int count = particleIndex->size();
		if ( vPositions.size() < count * 4 ) {
			vPositions.resize(count * 4);
			vColors.resize(count * 4);
		}

		nPositionIndex = 0;
		for ( auto it = particleIndex->begin(); it != particleIndex->end(); ++it ) {
			particle = (*it);

			c = cosf(particle->fRotation) * particle->fSize / 2.0f;
			s = sinf(particle->fRotation) * particle->fSize / 2.0f;

			x = particle->vPos.x;
			y = particle->vPos.y;

			vPositions[nPositionIndex + 0].set(x - c - s, y - c + s, 0);
			vPositions[nPositionIndex + 1].set(x - c + s, y + c + s, 0);
			vPositions[nPositionIndex + 2].set(x + c + s, y + c - s, 0);
			vPositions[nPositionIndex + 3].set(x + c - s, y - c - s, 0);

			vColors[nPositionIndex + 0] = particle->cColor;
			vColors[nPositionIndex + 1] = particle->cColor;
			vColors[nPositionIndex + 2] = particle->cColor;
			vColors[nPositionIndex + 3] = particle->cColor;

			nPositionIndex += 4;
		}

        static RenderUnit unit;
        unit.pPositions = &vPositions[0];
        unit.nPositionCount = nPositionIndex;
        unit.nIndexCount = nPositionIndex * 1.5;
        unit.color = &vColors[0];
        unit.bSameColor = false;
        unit.texture = texture;
        unit.renderType = RENDER_TYPE_TEXTURE;
        unit.shaderUsage = SU_TEXTURE;
        unit.flag = DEFAULT_INDEX | DEFAULT_TEXCOORD;
        
        return unit;
	}

	ParticleSystem::ParticleConfigMap ParticleSystem::parseParticlePlistFile(const char* filename)
	{
		ParticleConfigMap particleConfigMap;

		tinyxml2::XMLDocument doc;
        
		doc.LoadFile(filename);

		tinyxml2::XMLElement* root = doc.RootElement();
		tinyxml2::XMLNode* dict = root->FirstChildElement("dict");
		tinyxml2::XMLElement* ele = dict->FirstChildElement();

		std::string tmpstr1, tmpstr2;
		while ( ele ) {
			if ( ele->GetText() != nullptr && strcmp("textureImageData", ele->GetText()) == 0 ) {
				ele = ele->NextSiblingElement()->NextSiblingElement();
			}
			else {
				tmpstr1 = ele->GetText();
				ele = ele->NextSiblingElement();
				tmpstr2 = ele->GetText() == nullptr ? "0" : ele->GetText();
				ele = ele->NextSiblingElement();

				particleConfigMap.insert(std::make_pair(tmpstr1, tmpstr2));
			}
		}
		return particleConfigMap;
	}

	ParticleDescription ParticleSystem::createParticleDescription(ParticleConfigMap& map)
	{
		ParticleDescription desc;

		//================================== 发射器属性 ========================================

		/* 发射器角度 */
		desc.fEmitAngle	   = GET_I(map, "angle");
		desc.fEmitAngleVar = GET_I(map, "angleVariance");

		/* 发射器速度 */
		desc.fEmitSpeed	   = GET_I(map, "speed");
		desc.fEmitSpeedVar = GET_I(map, "speedVariance");

		// 发射器持续时间
		desc.fDuration     = GET_F(map, "duration");

		// 发射器模式（重力、径向）
		if ( GET_I(map, "emitterType") ) {
			desc.emitterType = EmitterType::EMITTER_TYPE_RADIUS;
		}
		else {
			desc.emitterType = EmitterType::EMITTER_TYPE_GRAVITY;
		}

		/* 最大粒子数量 */
		desc.nParticleCount = GET_F(map, "maxParticles");

		/* 发射区坐标 */
		desc.vEmitPos.set(GET_F(map, "sourcePositionx"), GET_F(map, "sourcePositiony"));
		desc.vEmitPosVar.set(GET_F(map, "sourcePositionVariancex"), GET_F(map, "sourcePositionVariancey"));

		/* 粒子生命周期 */
		desc.fLife    = GET_F(map, "particleLifespan");
		desc.fLifeVar = GET_F(map, "particleLifespanVariance");

		/* 发射速率 */
		desc.fEmitRate = desc.nParticleCount / desc.fLife;

		//================================== 粒子属性 ========================================

		/* 粒子起始颜色 */
		desc.cBeginColor.set(
			GET_F(map, "startColorRed"), 
			GET_F(map, "startColorGreen"), 
			GET_F(map, "startColorBlue"), 
			GET_F(map, "startColorAlpha"));

		desc.cBeginColorVar.set(
			GET_F(map, "startColorVarianceRed"),
			GET_F(map, "startColorVarianceGreen"),
			GET_F(map, "startColorVarianceBlue"),
			GET_F(map, "startColorVarianceAlpha"));

		/* 粒子结束颜色 */
		desc.cEndColor.set(
			GET_F(map, "finishColorRed"),
			GET_F(map, "finishColorGreen"),
			GET_F(map, "finishColorBlue"),
			GET_F(map, "finishColorAlpha"));

		desc.cEndColorVar.set(
			GET_F(map, "finishColorVarianceRed"),
			GET_F(map, "finishColorVarianceGreen"),
			GET_F(map, "finishColorVarianceBlue"),
			GET_F(map, "finishColorVarianceAlpha"));

		/* 粒子大小 */
		desc.fBeginSize		= GET_F(map, "startParticleSize");
		desc.fBeginSizeVar	= GET_F(map, "startParticleSizeVariance");
		desc.fEndSize		= GET_F(map, "finishParticleSize");
		desc.fEndSizeVar	= GET_F(map, "finishParticleSizeVariance");
									
		/* 粒子旋转 */				
		desc.fBeginSpin		= GET_F(map, "rotationStart");
		desc.fBeginSpinVar	= GET_F(map, "rotationStartVariance");
		desc.fEndSpin		= GET_F(map, "rotationEnd");
		desc.fEndSpinVar	= GET_F(map, "rotationEndVariance");

		/* 粒子运动模式 */
		MotionMode motionModes[2] = {
			MotionMode::MOTION_MODE_FREE,
			MotionMode::MOTION_MODE_RELATIVE
		};

		desc.motionMode = motionModes[GET_I(map, "positionType")];

		/* GravityMode 重力模式 */
		desc.gravityMode.vGravity.set(GET_F(map, "gravityx"), GET_F(map, "gravityy"));

		desc.gravityMode.fRadialAccel	 = GET_F(map, "radialAcceleration");
		desc.gravityMode.fRadialAccelVar = GET_F(map, "radialAccelVariance");

		desc.gravityMode.fTangentialAccel	 = GET_F(map, "tangentialAcceleration");
		desc.gravityMode.fTangentialAccelVar = GET_F(map, "tangentialAccelVariance");

		// RadiusMode 半径模式
		desc.radiusMode.fEndRadius = atof((map)["minRadius"].c_str());
		desc.radiusMode.fEndRadiusVar = atof((map)["minRadiusVariance"].c_str());

		desc.radiusMode.fBeginRadius = atof((map)["maxRadius"].c_str());
		desc.radiusMode.fBeginRadiusVar = atof((map)["maxRadiusVariance"].c_str());

		desc.radiusMode.fSpinPerSecond = atof((map)["rotatePerSecond"].c_str());
		desc.radiusMode.fSpinPerSecondVar = atof((map)["rotatePerSecondVariance"].c_str());

		return desc;
	}


	//-------------------------------------------------------------------------------
	// 粒子系统管理器
	// ParticleSystemManager
	//-------------------------------------------------------------------------------
	ParticleSystemManager::ParticleSystemManager()
	{
		ParticleMemory::initParticleMemory(1024);
	}

	ParticleSystemManager::~ParticleSystemManager()
	{
		for ( auto& ele : vParticleSystems ) {
			delete ele;
		}
		vParticleSystems.clear();

		ParticleMemory::freeParticleMemory();
	}

	void ParticleSystemManager::update(float dt)
	{
        
        
        
		for ( auto& ele : vParticleSystems ) {
			ele->update(dt);
		}
	}

    void ParticleSystemManager::render(std::vector<RenderUnit>& units)
	{
		for ( auto& ele : vParticleSystems ) {
           RenderUnit unit =  ele->render();
            units.push_back(unit);
		}
	}
}
