const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get community profile
router.get('/profile', authenticateToken, async (req, res, next) => {
  try {
    // Get user info from token
    const userId = req.user.userId;
    const userEmail = req.user.email;
    
    // Find community associated with this user
    const result = await db.query(`
      SELECT 
        c.id,
        c.community_name,
        c.location,
        c.contact_person,
        c.phone_number,
        c.email,
        c.description,
        c.established_year,
        c.member_count,
        c.photo_type,
        c.registration_status,
        c.rejection_reason,
        c.rejected_at,
        c.rejected_by,
        c.area_size,
        c.mangrove_species,
        c.conservation_status,
        c.website_url,
        c.social_media,
        c.village_name,
        c.sub_district,
        c.district,
        c.province,
        c.total_population,
        c.resource_dependent_population,
        c.households,
        c.main_occupation,
        c.main_religion,
        c.occupations,
        c.average_income,
        c.created_at,
        c.updated_at
      FROM communities c
      WHERE c.email = $1
    `, [userEmail]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลชุมชนที่ลงทะเบียนแล้ว'
      });
    }

    const community = result.rows[0];
    
    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลชุมชนสำเร็จ',
      data: {
        community: {
          id: community.id,
          name: community.community_name,
          location: community.location,
          contactPerson: community.contact_person,
          phoneNumber: community.phone_number,
          email: community.email,
          description: community.description,
          establishedYear: community.established_year,
          memberCount: community.member_count,
          photoType: community.photo_type,
          registrationStatus: community.registration_status,
          rejectionReason: community.rejection_reason,
          rejectedAt: community.rejected_at,
          rejectedBy: community.rejected_by,
          areaSize: community.area_size,
          mangroveSpecies: community.mangrove_species,
          conservationStatus: community.conservation_status,
          websiteUrl: community.website_url,
          socialMedia: community.social_media,
          villageName: community.village_name,
          subDistrict: community.sub_district,
          district: community.district,
          province: community.province,
          totalPopulation: community.total_population,
          resourceDependentPopulation: community.resource_dependent_population,
          households: community.households,
          mainOccupation: community.main_occupation,
          mainReligion: community.main_religion,
          occupations: community.occupations,
          averageIncome: community.average_income,
          createdAt: community.created_at,
          updatedAt: community.updated_at
        }
      }
    });

  } catch (error) {
    console.error('❌ Community profile error:', error);
    next(error);
  }
});

// Update community profile
router.put('/profile', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    const {
      name,
      villageName,
      subDistrict,
      district,
      province,
      location,
      areaSize,
      contactPerson,
      phoneNumber,
      websiteUrl,
      socialMedia,
      totalPopulation,
      resourceDependentPopulation,
      households,
      mainOccupation,
      mainReligion,
      occupations,
      averageIncome,
      mangroveSpecies,
      conservationStatus,
      description,
      establishedYear,
      memberCount
    } = req.body;

    // Convert empty strings to null for JSON/array fields
    const sanitizedOccupations = occupations && occupations !== '' ? occupations : null;
    const sanitizedSocialMedia = socialMedia && socialMedia !== '' ? socialMedia : null;
    const sanitizedMangroveSpecies = mangroveSpecies && mangroveSpecies !== '' ? mangroveSpecies : null;

    // Find community
    const communityResult = await db.query(
      'SELECT id FROM communities WHERE email = $1 AND registration_status = $2',
      [userEmail, 'approved']
    );

    if (communityResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลชุมชนที่ลงทะเบียนแล้ว'
      });
    }

   const communityId = communityResult.rows[0].id;

    // Update community data
    const updateResult = await db.query(`
      UPDATE communities 
      SET 
        community_name = COALESCE($1, community_name),
        village_name = COALESCE($2, village_name),
        sub_district = COALESCE($3, sub_district),
        district = COALESCE($4, district),
        province = COALESCE($5, province),
        location = COALESCE($6, location),
        area_size = COALESCE($7, area_size),
        contact_person = COALESCE($8, contact_person),
        phone_number = COALESCE($9, phone_number),
        website_url = COALESCE($10, website_url),
        social_media = COALESCE($11, social_media),
        total_population = COALESCE($12, total_population),
        resource_dependent_population = COALESCE($13, resource_dependent_population),
        households = COALESCE($14, households),
        main_occupation = COALESCE($15, main_occupation),
        main_religion = COALESCE($16, main_religion),
        occupations = COALESCE($17, occupations),
        average_income = COALESCE($18, average_income),
        mangrove_species = COALESCE($19, mangrove_species),
        conservation_status = COALESCE($20, conservation_status),
        description = COALESCE($21, description),
        established_year = COALESCE($22, established_year),
        member_count = COALESCE($23, member_count),
        updated_at = NOW()
      WHERE id = $24
      RETURNING *
    `, [
      name,
      villageName,
      subDistrict,
      district,
      province,
      location,
      areaSize,
      contactPerson,
      phoneNumber,
      websiteUrl,
      sanitizedSocialMedia, // Use sanitized value
      totalPopulation,
      resourceDependentPopulation,
      households,
      mainOccupation,
      mainReligion,
      sanitizedOccupations, // Use sanitized value
      averageIncome,
      sanitizedMangroveSpecies, // Use sanitized value
      conservationStatus,
      description,
      establishedYear,
      memberCount,
      communityId
    ]);

    const updatedCommunity = updateResult.rows[0];

    res.status(200).json({
      success: true,
      message: 'อัพเดทข้อมูลชุมชนสำเร็จ',
      data: {
        community: {
          id: updatedCommunity.id,
          name: updatedCommunity.community_name,
          villageName: updatedCommunity.village_name,
          subDistrict: updatedCommunity.sub_district,
          district: updatedCommunity.district,
          province: updatedCommunity.province,
          location: updatedCommunity.location,
          areaSize: updatedCommunity.area_size,
          contactPerson: updatedCommunity.contact_person,
          phoneNumber: updatedCommunity.phone_number,
          email: updatedCommunity.email,
          websiteUrl: updatedCommunity.website_url,
          socialMedia: updatedCommunity.social_media,
          totalPopulation: updatedCommunity.total_population,
          resourceDependentPopulation: updatedCommunity.resource_dependent_population,
          households: updatedCommunity.households,
          mainOccupation: updatedCommunity.main_occupation,
          mainReligion: updatedCommunity.main_religion,
          occupations: updatedCommunity.occupations,
          averageIncome: updatedCommunity.average_income,
          mangroveSpecies: updatedCommunity.mangrove_species,
          conservationStatus: updatedCommunity.conservation_status,
          description: updatedCommunity.description,
          establishedYear: updatedCommunity.established_year,
          memberCount: updatedCommunity.member_count,
          updatedAt: updatedCommunity.updated_at
        }
      }
    });

  } catch (error) {
    console.error('❌ Community profile update error:', error);
    next(error);
  }
});

module.exports = router;